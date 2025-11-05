class Skill < Formula
  desc 'Vendor and manage LLM skills from a central repository'
  homepage 'https://github.com/DockYard/skill'
  version '0.1.0'
  license 'MIT'

  on_macos do
    if Hardware::CPU.arm?
      url 'https://github.com/DockYard/skill/releases/download/v0.1.0/skill-macos-aarch64.tar.gz'
      sha256 'PLACEHOLDER_ARM64_SHA256'
    else
      url 'https://github.com/DockYard/skill/releases/download/v0.1.0/skill-macos-x86_64.tar.gz'
      sha256 'PLACEHOLDER_X86_64_SHA256'
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url 'https://github.com/DockYard/skill/releases/download/v0.1.0/skill-linux-aarch64.tar.gz'
      sha256 'PLACEHOLDER_LINUX_ARM64_SHA256'
    else
      url 'https://github.com/DockYard/skill/releases/download/v0.1.0/skill-linux-x86_64.tar.gz'
      sha256 'PLACEHOLDER_LINUX_X86_64_SHA256'
    end
  end

  def install
    bin.install 'skill'
  end

  test do
    assert_match 'skill version', shell_output("#{bin}/skill --version")
  end
end
