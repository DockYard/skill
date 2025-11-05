const std = @import("std");

pub fn print(comptime fmt: []const u8, args: anytype) !void {
    var buf: [4096]u8 = undefined;
    const text = try std.fmt.bufPrint(&buf, fmt, args);
    try std.fs.File.stdout().writeAll(text);
}

pub fn eprint(comptime fmt: []const u8, args: anytype) !void {
    var buf: [4096]u8 = undefined;
    const text = try std.fmt.bufPrint(&buf, fmt, args);
    try std.fs.File.stderr().writeAll(text);
}

pub fn println(text: []const u8) !void {
    try std.fs.File.stdout().writeAll(text);
    try std.fs.File.stdout().writeAll("\n");
}

pub fn eprintln(text: []const u8) !void {
    try std.fs.File.stderr().writeAll(text);
    try std.fs.File.stderr().writeAll("\n");
}

pub fn readLine(allocator: std.mem.Allocator) ![]const u8 {
    const stdin = std.fs.File.stdin();
    return try stdin.reader().readUntilDelimiterAlloc(allocator, '\n', 1024);
}
