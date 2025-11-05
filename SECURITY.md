# Security Analysis

This document contains a comprehensive security analysis of the `skill` CLI tool, identifying potential attack vectors and providing mitigation recommendations.

## Executive Summary

**Overall Risk Level: MEDIUM-HIGH**

The tool has several security vulnerabilities that should be addressed before production use, particularly around:
- Path traversal attacks via malicious skill names
- Command injection via repository URLs and skill names
- Symlink attacks during file operations
- TOCTOU (Time-of-check-time-of-use) race conditions
- Unsafe temp directory handling

## Critical Vulnerabilities

### 1. Path Traversal via Skill Names ⚠️ CRITICAL

**Location:** `src/git.zig:134`, `src/git.zig:159`, `src/commands.zig` (multiple locations)

**Issue:** Skill names from the remote repository are not validated before being used in file paths. A malicious repository could contain directory names like:
- `../../../etc/passwd` 
- `..%2F..%2F..%2Fetc%2Fpasswd`
- `.git`
- Skill names with null bytes, newlines, or other special characters

**Attack Scenario:**
```bash
# Attacker creates malicious repo with directory named "../../../.ssh"
skill add "../../../.ssh"
# Could overwrite ~/.ssh/ directory
```

**Code Example:**
```zig
// git.zig:134 - No validation before writing
const pattern = try std.fmt.allocPrint(allocator, "{s}/\n", .{skill_name});
try sparse_file.writeAll(pattern);

// git.zig:159 - No validation before path join
const skill_source = try std.fs.path.join(allocator, &[_][]const u8{ temp_dir_path, skill_name });
```

**Mitigation:**
```zig
fn validateSkillName(name: []const u8) !void {
    // Reject names with path separators
    if (std.mem.indexOf(u8, name, "/") != null) return error.InvalidSkillName;
    if (std.mem.indexOf(u8, name, "\\") != null) return error.InvalidSkillName;
    
    // Reject relative path components
    if (std.mem.eql(u8, name, ".")) return error.InvalidSkillName;
    if (std.mem.eql(u8, name, "..")) return error.InvalidSkillName;
    if (std.mem.startsWith(u8, name, ".")) return error.InvalidSkillName;
    
    // Reject null bytes and control characters
    for (name) |c| {
        if (c == 0 or c < 32) return error.InvalidSkillName;
    }
    
    // Maximum length check
    if (name.len == 0 or name.len > 255) return error.InvalidSkillName;
}
```

### 2. Command Injection via Repository URL ⚠️ CRITICAL

**Location:** `src/git.zig:34`, `src/git.zig:116`

**Issue:** Repository URLs from user input or config files are passed directly to git commands without validation. A malicious URL could inject additional git arguments or shell commands.

**Attack Scenario:**
```bash
skill init --repo "$(malicious command)"
skill init --repo "--upload-pack='arbitrary code'"
```

**Code Example:**
```zig
// git.zig:34 - cfg.repo used directly without validation
try runGitCommand(allocator, &[_][]const u8{ "git", "remote", "add", "origin", cfg.repo }, temp_dir_path);
```

**Mitigation:**
```zig
fn validateRepositoryURL(url: []const u8) !void {
    // Only allow known URL schemes
    const valid_schemes = [_][]const u8{ "git@", "https://", "http://", "ssh://", "file://" };
    var valid = false;
    for (valid_schemes) |scheme| {
        if (std.mem.startsWith(u8, url, scheme)) {
            valid = true;
            break;
        }
    }
    if (!valid) return error.InvalidRepositoryURL;
    
    // Reject URLs with shell metacharacters
    const dangerous_chars = "$`;&|><(){}[]!";
    for (dangerous_chars) |c| {
        if (std.mem.indexOf(u8, url, &[_]u8{c}) != null) {
            return error.InvalidRepositoryURL;
        }
    }
    
    // Reject git arguments that start with -
    if (std.mem.startsWith(u8, url, "-")) return error.InvalidRepositoryURL;
}
```

### 3. Symlink Attacks During File Copy ⚠️ HIGH

**Location:** `src/git.zig:189-209`

**Issue:** `copyDirectory()` follows symlinks without checking, which could allow:
- Copying sensitive files from outside the intended directory
- Creating symlinks that point to sensitive system files
- Time-of-check-time-of-use (TOCTOU) attacks

**Attack Scenario:**
```bash
# Malicious skill repo contains:
# skill-name/passwd -> /etc/passwd
# skill-name/shadow -> /etc/shadow
skill add skill-name
# Now skills/skill-name/passwd contains /etc/passwd contents
```

**Code Example:**
```zig
// git.zig:206 - copyFile follows symlinks by default
try source_dir.copyFile(entry.name, dest_dir, entry.name, .{});
```

**Mitigation:**
```zig
fn copyDirectory(allocator: std.mem.Allocator, source: []const u8, dest: []const u8) !void {
    var source_dir = try std.fs.openDirAbsolute(source, .{ .iterate = true, .no_follow = true });
    defer source_dir.close();

    try std.fs.cwd().makePath(dest);
    var dest_dir = try std.fs.cwd().openDir(dest, .{});
    defer dest_dir.close();

    var iter = source_dir.iterate();
    while (try iter.next()) |entry| {
        // Skip symlinks entirely
        if (entry.kind == .sym_link) {
            std.debug.print("Warning: Skipping symlink: {s}\n", .{entry.name});
            continue;
        }
        
        if (entry.kind == .directory) {
            const sub_source = try std.fs.path.join(allocator, &[_][]const u8{ source, entry.name });
            defer allocator.free(sub_source);
            const sub_dest = try std.fs.path.join(allocator, &[_][]const u8{ dest, entry.name });
            defer allocator.free(sub_dest);
            try copyDirectory(allocator, sub_source, sub_dest);
        } else if (entry.kind == .file) {
            // Use no_follow flag
            try source_dir.copyFile(entry.name, dest_dir, entry.name, .{ .no_follow = true });
        }
    }
}
```

### 4. Race Conditions in Temp Directory Creation ⚠️ HIGH

**Location:** `src/git.zig:20-28`, `src/git.zig:102-110`

**Issue:** Temp directory creation uses timestamp-based names, which creates a race condition window where an attacker could:
- Predict the directory name
- Create it before the legitimate process
- Place malicious content there
- Cause the tool to operate on attacker-controlled data

**Attack Scenario:**
```bash
# Attacker predicts temp directory name and creates it first
while true; do
  mkdir -p /tmp/skill-$(date +%s%3N) 2>/dev/null
done

# When user runs: skill list
# Tool might use attacker's pre-created directory
```

**Code Example:**
```zig
// git.zig:21 - Predictable temp directory name
const temp_name = try std.fmt.allocPrint(allocator, "skill-{d}", .{std.time.milliTimestamp()});
```

**Mitigation:**
```zig
fn createSecureTempDir(allocator: std.mem.Allocator) ![]const u8 {
    const tmp_base = std.posix.getenv("TMPDIR") orelse std.posix.getenv("TEMP") orelse "/tmp";
    
    // Use cryptographically random name
    var random_bytes: [16]u8 = undefined;
    std.crypto.random.bytes(&random_bytes);
    
    var name_buf: [32]u8 = undefined;
    const random_name = std.fmt.bufPrint(&name_buf, "skill-{x}", .{random_bytes}) catch unreachable;
    
    const temp_dir_path = try std.fs.path.join(allocator, &[_][]const u8{ tmp_base, random_name });
    
    // Create with exclusive flag - fails if exists
    std.fs.makeDirAbsolute(temp_dir_path) catch |err| {
        allocator.free(temp_dir_path);
        return err;
    };
    
    // Set restrictive permissions (700)
    const dir = try std.fs.openDirAbsolute(temp_dir_path, .{});
    defer dir.close();
    try dir.chmod(0o700);
    
    return temp_dir_path;
}
```

## High Severity Issues

### 5. Arbitrary File Overwrite via skill update

**Location:** `src/commands.zig:335-383`

**Issue:** `skill update` deletes and recreates skill directories. If a skill name contains path traversal, it could delete arbitrary directories.

**Mitigation:** Validate skill names before any filesystem operations.

### 6. HOME Directory Manipulation

**Location:** `src/config.zig:32`, `src/config.zig:167`

**Issue:** The tool trusts the `HOME` environment variable without validation. An attacker with control over environment variables could:
- Redirect config loading to attacker-controlled files
- Cause the tool to create/modify files in unexpected locations

**Mitigation:**
```zig
fn getSecureHomeDir() ![]const u8 {
    const home = std.posix.getenv("HOME") orelse return error.NoHomeDirectory;
    
    // Validate home directory exists and is a directory
    var dir = std.fs.openDirAbsolute(home, .{}) catch return error.InvalidHomeDirectory;
    dir.close();
    
    // Check it's not a symlink
    const stat = std.fs.cwd().statFile(home) catch return error.InvalidHomeDirectory;
    if (stat.kind != .directory) return error.InvalidHomeDirectory;
    
    return home;
}
```

### 7. Config File Size Limit Bypass

**Location:** `src/config.zig:60`

**Issue:** Config files are limited to 1MB, but this doesn't prevent:
- Memory exhaustion through JSON parsing
- Deeply nested JSON structures causing stack overflow
- Malicious JSON with many repeated keys

**Mitigation:**
```zig
const content = try file.readToEndAlloc(allocator, 64 * 1024); // Reduce to 64KB
// Add depth limit to JSON parsing
const parsed = try std.json.parseFromSlice(
    std.json.Value,
    allocator,
    cleaned,
    .{ .max_value_len = 64 * 1024 },
);
```

### 8. Shell Script Injection in install.sh

**Location:** `scripts/install.sh:73`

**Issue:** The install script uses unquoted variables that could allow command injection:

```bash
mv "skill-${OS_NAME}-${ARCH_NAME}/skill" "$INSTALL_DIR/skill"
```

If `OS_NAME` or `ARCH_NAME` contained shell metacharacters, it could execute arbitrary commands.

**Mitigation:** Already partially mitigated by `set -e`, but should add:
```bash
set -euo pipefail  # Add 'u' for undefined variables, 'o pipefail' for pipeline failures
```

## Medium Severity Issues

### 9. TOCTOU in Directory Existence Checks

**Location:** Multiple locations checking directory/file existence before operations

**Issue:** Time gap between checking if directory exists and performing operations.

### 10. Unsafe Error Message Information Disclosure

**Location:** `src/git.zig:179`

**Issue:** Git error messages are printed directly to stderr, potentially leaking:
- Repository structure information
- Authentication credentials in URLs
- System paths
- Internal git configurations

**Mitigation:** Sanitize error messages before displaying.

### 11. No Integrity Verification

**Issue:** Downloaded skills have no integrity verification:
- No checksums
- No signatures
- No verification that content matches expectations

**Mitigation:** Add support for:
- GPG signature verification
- SHA256 checksums in a manifest file
- Signed git tags

### 12. Denial of Service via Large Skills

**Issue:** No limits on:
- Skill directory size
- Number of files in a skill
- Depth of directory nesting

**Mitigation:** Add resource limits before copying.

## Low Severity Issues

### 13. Temp Directory Cleanup Failure

**Location:** `src/git.zig:28`, `src/git.zig:110`

**Issue:** Temp directory cleanup uses `catch {}` which silently ignores failures, potentially leaving sensitive data on disk.

**Mitigation:** Log cleanup failures and implement retry logic.

### 14. No Rate Limiting on Git Operations

**Issue:** No protection against:
- Rapid repeated git fetches
- DoS of remote git server
- Local resource exhaustion

### 15. TMPDIR Environment Variable Manipulation

**Location:** `src/git.zig:20`, `src/git.zig:102`

**Issue:** Trusts `TMPDIR` environment variable without validation.

## Recommendations

### Immediate Actions (Before Production Use)

1. **Implement skill name validation** - Block all path traversal attempts
2. **Implement repository URL validation** - Whitelist URL schemes and block shell metacharacters
3. **Fix symlink handling** - Never follow symlinks during copy operations
4. **Use secure temp directory creation** - Cryptographic randomness + exclusive creation
5. **Add resource limits** - Max file size, max files per skill, max directory depth

### Short Term (Within 1-2 Releases)

1. **Add integrity verification** - SHA256 checksums or GPG signatures
2. **Implement proper error sanitization** - Don't leak sensitive information
3. **Add security documentation** - Document trust model and security assumptions
4. **Security audit of shell scripts** - Review all bash scripts for injection vulnerabilities
5. **Add security tests** - Unit tests for path traversal, command injection, etc.

### Long Term

1. **Sandboxing** - Run git operations in restricted environment
2. **Code signing** - Sign released binaries
3. **Security scanning** - Automated security testing in CI/CD
4. **Formal security review** - Third-party security audit
5. **Bug bounty program** - Responsible disclosure process

## Testing Security

Run these tests to verify security improvements:

```bash
# Test 1: Path traversal in skill names
skill add "../../../etc"  # Should be rejected

# Test 2: Command injection in repo URL
skill init --repo '$(whoami)'  # Should be rejected

# Test 3: Symlink attack
# Create malicious repo with symlink, attempt to add

# Test 4: Race condition in temp dir
# Run multiple instances simultaneously

# Test 5: Large skill DoS
# Create skill with 100k files, attempt to add
```

## Security Contact

For security issues, please email: security@dockyard.com

Do not file public issues for security vulnerabilities.

## References

- CWE-22: Improper Limitation of a Pathname to a Restricted Directory ('Path Traversal')
- CWE-78: Improper Neutralization of Special Elements used in an OS Command ('OS Command Injection')
- CWE-367: Time-of-check Time-of-use (TOCTOU) Race Condition
- CWE-59: Improper Link Resolution Before File Access ('Link Following')
- CWE-377: Insecure Temporary File
