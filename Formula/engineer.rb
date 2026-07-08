class Engineer < Formula
  desc "Terminal client for the Engineer study-tracking app"
  homepage "https://engineer.dsaenz.dev/developers/cli"
  version "0.6.0"
  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.6.0/engineer-cli-aarch64-apple-darwin.tar.xz"
      sha256 "a87317c09647bca502c4c6500dc9e9abda54f5cb81a49cc3f77aad5770bc9164"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.6.0/engineer-cli-x86_64-apple-darwin.tar.xz"
      sha256 "0fe76d6cd726b38b23c5c1477de4535c04b813866c80606eeead4505d6fdb1b2"
    end
  end
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.6.0/engineer-cli-aarch64-unknown-linux-gnu.tar.xz"
      sha256 "c9daa1be5c975cd7b49c887735cb6560c4c475cff4187ae458d9446244857197"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dsaenztagarro/engineer-cli/releases/download/v0.6.0/engineer-cli-x86_64-unknown-linux-gnu.tar.xz"
      sha256 "e835294e90ed188f9bbf7929ce44d493488a4dd77c4de3bd8d33985fac20f6ad"
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
