class Skill < Formula
  desc 'Vendor and manage LLM skills from a central repository'
  homepage 'https://github.com/DockYard/skill'
  version '0.2.0'
  license 'MIT'

  on_macos do
    if Hardware::CPU.arm?
      url 'https://github.com/DockYard/skill/releases/download/v0.2.0/skill-macos-aarch64.tar.gz'
      sha256 'fde443551ce7391497825cff6878055cd884008e459bbe46ef395b9014b7fb2a'
    else
      url 'https://github.com/DockYard/skill/releases/download/v0.2.0/skill-macos-x86_64.tar.gz'
      sha256 'bb812e0675c97e0e1043af06784f9d191a4883713c00e72c9b46d1d36413a4c8'
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url 'https://github.com/DockYard/skill/releases/download/v0.2.0/skill-linux-aarch64.tar.gz'
      sha256 '2ea8cdb52d6061bf094780f0e7fe11777ace3c046cd0bfeddd2be0a871d85c82'
    else
      url 'https://github.com/DockYard/skill/releases/download/v0.2.0/skill-linux-x86_64.tar.gz'
      sha256 '298d34be6caf0fa84de202b7d31932ed6ee8cc39808ed818e70338a951f596a7'
    end
  end

  def install
    bin.install 'skill'
  end

  test do
    assert_match 'skill version', shell_output("#{bin}/skill --version")
  end
end
