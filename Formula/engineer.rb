class Engineer < Formula
  desc "Terminal client for the Engineer study-tracking app"
  homepage "https://engineer.dsaenz.dev/developers/cli"
  version "0.7.0"
  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.7.0/engineer-cli-aarch64-apple-darwin.tar.xz"
      sha256 "6c7660abadeb8d64ec7c8e6c73bfe2c8f341c8607071faa1edbb7767139c2146"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.7.0/engineer-cli-x86_64-apple-darwin.tar.xz"
      sha256 "81a2cd57d7bb665cabe14d944f879481406a6dd5fbcca328bc1e5ee644ecd875"
    end
  end
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.7.0/engineer-cli-aarch64-unknown-linux-gnu.tar.xz"
      sha256 "b82519d9ccd7c117cf79092ef4d150eb1912fd3db46ef227ee7886d4e9048de2"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.7.0/engineer-cli-x86_64-unknown-linux-gnu.tar.xz"
      sha256 "54f01deb9a850dafdb77bb826d3559dcffaac085c5622948727fac651e868ca5"
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
