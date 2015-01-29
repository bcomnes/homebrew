require "language/javascript"

class Iojs < Formula
  include Language::JS

  homepage "https://iojs.org/"
  url "https://iojs.org/dist/v1.6.1/iojs-v1.6.1.tar.xz"
  sha256 "d5854af15ee48b314dbcbcb8ccd59b4e11163aa99a50f67f5d90c0773ac76d8a"

  bottle do
    sha256 "84cf8a9eb38e7ffc49c2cb59eb7b5be254d264dd73b8ac1c549b4c9bcfbae286" => :yosemite
    sha256 "11f03e7c246e891b392e7c19b79616402823ef600859e92d894458732768aecd" => :mavericks
    sha256 "f57cfc8ebae21a8d0499d6181f55f5ccab06bfa14438f7e6dd2dde773d4dd28d" => :mountain_lion
  end

  conflicts_with "node", :because => "node and iojs both install a binary/link named node"

  option "with-debug", "Build with debugger hooks"
  option "with-icu4c", "Build with Intl (icu4c) support"
  option "without-npm", "npm will not be installed"
  option "without-completion", "npm bash completion will not be installed"

  depends_on "pkg-config" => :build
  depends_on "icu4c" => :optional
  depends_on :python => :build

  resource "npm" do
    url "https://registry.npmjs.org/npm/-/npm-2.5.1.tgz"
    sha1 "23e4b0fdd1ffced7d835780e692a9e5a0125bb02"
  end

  def install
    args = %W[--prefix=#{prefix} --without-npm]
    args << "--debug" if build.with? "debug"
    args << "--with-intl=system-icu" if build.with? "icu4c"

    system "./configure", *args
    system "make", "install"

    if build.with? "npm"
      resource("npm").stage npm_buildpath = buildpath/"npm_install"
      install_npm npm_buildpath

      if build.with? "completion"
        install_npm_bash_completion npm_buildpath
      end
    end
  end

  def post_install
    return if build.without? "npm"

    npm_post_install libexec
  end

  def caveats
    s = ""

    if build.with? "npm"
      s += <<-EOS.undent
        npm has been installed. To update run
          npm install -g npm@latest

        You can install global npm packages with
          npm install -g <package>

        They will install into the global node_modiles directory
          #{HOMEBREW_PREFIX}/lib/node_modules

        Do NOT use the npm update command with global modules.
        The upstream-recommended way to update global modules is:
          npm install -g <package>@latest
      EOS
    else
      s += <<-EOS.undent
        Homebrew has NOT installed npm. If you later install it, you should supplement
        your NODE_PATH with the npm module folder:
          #{HOMEBREW_PREFIX}/lib/node_modules
      EOS
    end

    s
  end

  test do
    path = testpath/"test.js"
    path.write "console.log('hello');"

    output = `#{bin}/iojs #{path}`.strip
    assert_equal "hello", output
    assert_equal 0, $?.exitstatus

    if build.with? "npm"
      # make sure npm can find node
      ENV.prepend_path "PATH", opt_bin
      assert_equal which("node"), opt_bin/"node"
      npm_test_install
    end
  end
end

