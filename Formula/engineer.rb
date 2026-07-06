class Engineer < Formula
  desc "Terminal client for the Engineer study-tracking app"
  homepage "https://engineer.dsaenz.dev/developers/cli"
  version "0.4.0"
  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.4.0/engineer-cli-aarch64-apple-darwin.tar.xz"
      sha256 "f92c04134f767387555baa42d6d44c8589fc657dda31cc9c18bca481f3dde5b6"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.4.0/engineer-cli-x86_64-apple-darwin.tar.xz"
      sha256 "e8528a611fd9acad2b1952f43cbc873f74c819a06b0e465bf27cacd80af63f62"
    end
  end
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.4.0/engineer-cli-aarch64-unknown-linux-gnu.tar.xz"
      sha256 "63205fe5e48a1323f6b0c70fb6319ac8548e0d69f9b215ee5f743acf5ecce07a"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.4.0/engineer-cli-x86_64-unknown-linux-gnu.tar.xz"
      sha256 "6170ceeca08e85790e62549fc9d8fc1e0c44b565701698d2084c9d30f7fb6286"
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
