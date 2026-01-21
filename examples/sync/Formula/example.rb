# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula

class Example < Formula
  desc "Short description of your tool (max ~80 chars)"
  homepage "https://github.com/radiolabme/your-repo"
  url "https://github.com/radiolabme/your-repo/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  license "MIT"
  head "https://github.com/radiolabme/your-repo.git", branch: "main"

  # Uncomment dependencies as needed:
  #
  # Build-time only:
  # depends_on "go" => :build
  # depends_on "rust" => :build
  # depends_on "cmake" => :build
  # depends_on "node" => :build
  #
  # Runtime:
  # depends_on "python@3.12"
  # depends_on "openssl@3"

  def install
    # ============================================
    # Go project (building from source)
    # ============================================
    # system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")

    # ============================================
    # Rust project
    # ============================================
    # system "cargo", "install", *std_cargo_args

    # ============================================
    # Python project
    # ============================================
    # virtualenv_install_with_resources

    # ============================================
    # Node.js project
    # ============================================
    # system "npm", "install", *std_npm_args
    # bin.install_symlink Dir["#{libexec}/bin/*"]

    # ============================================
    # Makefile project
    # ============================================
    # system "make", "install", "PREFIX=#{prefix}"

    # ============================================
    # Pre-built binary (from release assets)
    # ============================================
    # bin.install "your-tool"

    # ============================================
    # Shell script
    # ============================================
    # bin.install "your-script.sh" => "your-tool"
  end

  test do
    # Minimal test to verify installation works
    # This runs during `brew test your-tool`

    # Version check (most common)
    system bin/"example", "--version"

    # Or check help output
    # assert_match "Usage:", shell_output("#{bin}/example --help")

    # Or run a simple command
    # assert_match "expected output", shell_output("#{bin}/example echo hello")
  end
end
