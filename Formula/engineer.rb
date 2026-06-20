class Engineer < Formula
  desc "Terminal client for the Engineer study-tracking app"
  homepage "https://engineer.dsaenz.dev/developers/cli"
  version "0.2.0"
  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.2.0/engineer-cli-aarch64-apple-darwin.tar.xz"
      sha256 "24e2e06e7cce4748588b44f8ee3a7d06c6111bcfc2c1e2d07515ae26195bdd2e"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.2.0/engineer-cli-x86_64-apple-darwin.tar.xz"
      sha256 "0aec65545845212b315841eae617e49976e1128979b9702c2601b03f8a49c7d1"
    end
  end
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.2.0/engineer-cli-aarch64-unknown-linux-gnu.tar.xz"
      sha256 "05183d9ca4962db8c98926059e902cf0e0594d162045326139c72c50f11fc783"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.2.0/engineer-cli-x86_64-unknown-linux-gnu.tar.xz"
      sha256 "33ca568d230fa7388ad6134a97ba43e47a9f7b1461e1390e9cf7e4f8de47521e"
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
