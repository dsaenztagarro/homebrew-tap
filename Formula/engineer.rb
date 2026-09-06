class Engineer < Formula
  desc "Terminal client for the Engineer study-tracking app"
  homepage "https://engineer.dsaenz.dev/developers/cli"
  version "0.11.1"
  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.11.1/engineer-cli-aarch64-apple-darwin.tar.xz"
      sha256 "00bfee3814e2cb5f59ab768d6b1906bd134c02657bde1d28bf9e758cfee574bb"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.11.1/engineer-cli-x86_64-apple-darwin.tar.xz"
      sha256 "972912889fba8f49dc10a05a1db04ca51df020149882ab90d5fcb7a9457575bf"
    end
  end
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.11.1/engineer-cli-aarch64-unknown-linux-gnu.tar.xz"
      sha256 "09594b4e62e38b7fa3c9427bfe85f23cb0db6cd243ad8c972983b3694b7a5e41"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.11.1/engineer-cli-x86_64-unknown-linux-gnu.tar.xz"
      sha256 "500d262322d87d8c0b759b1525e064bbea3e0a36982518f1879eb979867b845c"
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
    if OS.mac? && Hardware::CPU.arm?
      bin.install "engineer"
    end
    if OS.mac? && Hardware::CPU.intel?
      bin.install "engineer"
    end
    if OS.linux? && Hardware::CPU.arm?
      bin.install "engineer"
    end
    if OS.linux? && Hardware::CPU.intel?
      bin.install "engineer"
    end

    install_binary_aliases!

    # Homebrew will automatically install these, so we don't need to do that
    doc_files = Dir["README.*", "readme.*", "LICENSE", "LICENSE.*", "CHANGELOG.*"]
    leftover_contents = Dir["*"] - doc_files

    # Install any leftover files in pkgshare; these are probably config or
    # sample files.
    pkgshare.install(*leftover_contents) unless leftover_contents.empty?
  end
end
