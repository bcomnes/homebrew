require "language/javascript"

# Note that x.even are stable releases, x.odd are devel releases
class Node < Formula
  include Language::JS

  homepage "https://nodejs.org/"
  url "https://nodejs.org/dist/v0.12.0/node-v0.12.0.tar.gz"
  sha256 "9700e23af4e9b3643af48cef5f2ad20a1331ff531a12154eef2bfb0bb1682e32"
  head "https://github.com/joyent/node.git", :branch => "v0.12"
  revision 1

  bottle do
    sha256 "145227f47243194323891218b32e6acca98a994770156c631978d29a5a5d3cc8" => :yosemite
    sha256 "6796aa8bde6bc7919d075a99977a156e1bdad3b51a0de3eeccd6483a48b3e16a" => :mavericks
    sha256 "0d75a70bc7e39df1f7bf24424245db1b3f7b816d107cd154e4d6becb0069fed2" => :mountain_lion
  end

  conflicts_with "iojs", :because => "node and iojs both install a binary/link named node"

  option "with-debug", "Build with debugger hooks"
  option "without-npm", "npm will not be installed"
  option "without-completion", "npm bash completion will not be installed"

  deprecated_option "enable-debug" => "with-debug"

  depends_on :python => :build
  depends_on "pkg-config" => :build
  depends_on "openssl" => :optional

  # https://github.com/joyent/node/issues/7919
  # https://github.com/Homebrew/homebrew/issues/36681
  depends_on "icu4c" => :optional

  fails_with :llvm do
    build 2326
  end

  resource "npm" do
    url "https://registry.npmjs.org/npm/-/npm-2.7.1.tgz"
    sha256 "dda316a9abe1881c220e7db3b04e240e6f44179825d3c143b72e4734d2ac1046"
  end

  def install
    args = %W[--prefix=#{prefix} --without-npm]
    args << "--debug" if build.with? "debug"
    args << "--with-intl=system-icu" if build.with? "icu4c"

    if build.with? "openssl"
      args << "--shared-openssl"
    else
      args << "--without-ssl2" << "--without-ssl3"
    end

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

    if build.with? "icu4c"
      s += <<-EOS.undent

        Please note `icu4c` is built with a newer deployment target than Node and
        this may cause issues in certain usage. Node itself is built against the
        outdated `libstdc++` target, which is the root cause. For more information see:
          https://github.com/joyent/node/issues/7919

        If this is an issue for you, do `brew install node --without-icu4c`.
      EOS
    end

    s
  end

  test do
    path = testpath/"test.js"
    path.write "console.log('hello');"

    output = `#{bin}/node #{path}`.strip
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
