class Engineer < Formula
  desc "Terminal client for the Engineer study-tracking app"
  homepage "https://engineer.dsaenz.dev/developers/cli"
  version "0.11.0"
  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.11.0/engineer-cli-aarch64-apple-darwin.tar.xz"
      sha256 "9eec5a37c37246502a7026c211fd4d19ec30552dc91368f6f73e47c0a415eced"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.11.0/engineer-cli-x86_64-apple-darwin.tar.xz"
      sha256 "0bbe888b468ad9eef9233c25e8f9563da0927638c141aa8983b518725351232f"
    end
  end
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.11.0/engineer-cli-aarch64-unknown-linux-gnu.tar.xz"
      sha256 "044a6a5c36883f5ec3cb4ef162991b86a0326d7ca435c2026ea331b0d5a2ad43"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.11.0/engineer-cli-x86_64-unknown-linux-gnu.tar.xz"
      sha256 "c716e969805ca9a60b855a800ce143cafc2d2a0c5877c4046cfc96a661345711"
    end
  end
  license "MIT"

  BINARY_ALIASES = {
    "aarch64-apple-darwin":      {},
    "aarch64-unknown-linux-gnu": {},
    "x86_64-apple-darwin":       {},
    "x86_64-unknown-linux-gnu":  {},
  }.freeze

  def target_triple
    cpu = Hardware::CPU.arm? ? "aarch64" : "x86_64"
    os = OS.mac? ? "apple-darwin" : "unknown-linux-gnu"

    "#{cpu}-#{os}"
  end

  def install_binary_aliases!
    BINARY_ALIASES[target_triple.to_sym].each do |source, dests|
      dests.each do |dest|
        bin.install_symlink bin/source.to_s => dest
      end
    end
  end

  def install
    bin.install "engineer" if OS.mac? && Hardware::CPU.arm?
    bin.install "engineer" if OS.mac? && Hardware::CPU.intel?
    bin.install "engineer" if OS.linux? && Hardware::CPU.arm?
    bin.install "engineer" if OS.linux? && Hardware::CPU.intel?

    install_binary_aliases!

    # Homebrew will automatically install these, so we don't need to do that
    doc_files = Dir["README.*", "readme.*", "LICENSE", "LICENSE.*", "CHANGELOG.*"]
    leftover_contents = Dir["*"] - doc_files

    # Install any leftover files in pkgshare; these are probably config or
    # sample files.
    pkgshare.install(*leftover_contents) unless leftover_contents.empty?
  end
end
