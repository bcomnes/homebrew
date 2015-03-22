module Language
  module JS
    def self.install_npm npm_buildpath, node_buildpath, bin, libexec
      # make sure npm can find node
      ENV.prepend_path "PATH", bin
      # make sure user prefix settings in $HOME are ignored
      ENV["HOME"] = node_buildpath/"home"
      # set log level temporarily for npm's `make install`
      ENV["NPM_CONFIG_LOGLEVEL"] = "verbose"

      FileUtils.cd npm_buildpath do
        system "./configure", "--prefix=#{libexec}/npm"
        system "make", "install"
      end
    end

    def self.install_npm_bash_completion bash_completion, npm_buildpath
      bash_completion.install \
          npm_buildpath/"lib/utils/completion.sh" => "npm"
    end

    def self.npm_post_install libexec
      node_modules = HOMEBREW_PREFIX/"lib/node_modules"
      node_modules.mkpath
      npm_exec = node_modules/"npm/bin/npm-cli.js"
      # Kill npm but preserve all other modules across node updates/upgrades.
      FileUtils.rm_rf node_modules/"npm"

      FileUtils.cp_r libexec/"npm/lib/node_modules/npm", node_modules
      # This symlink doesn't hop into homebrew_prefix/bin automatically so
      # remove it and make our own. This is a small consequence of our bottle
      # npm make install workaround. All other installs **do** symlink to
      # homebrew_prefix/bin correctly. We ln rather than cp this because doing
      # so mimics npm's normal install.
      FileUtils.ln_sf npm_exec, "#{HOMEBREW_PREFIX}/bin/npm"

      # Let's do the manpage dance. It's just a jump to the left.
      # And then a step to the right, with your hand on rm_f.
      ["man1", "man3", "man5", "man7"].each do |man|
        # Dirs must exist first: https://github.com/Homebrew/homebrew/issues/35969
        FileUtils.mkdir_p HOMEBREW_PREFIX/"share/man/#{man}"
        FileUtils.rm_f Dir[HOMEBREW_PREFIX/"share/man/#{man}/{npm.,npm-,npmrc.}*"]
        FileUtils.ln_sf Dir[libexec/"npm/share/man/#{man}/npm*"], HOMEBREW_PREFIX/"share/man/#{man}"
      end

      npm_root = node_modules/"npm"
      npmrc = npm_root/"npmrc"
      npmrc.atomic_write("prefix = #{HOMEBREW_PREFIX}\n")
    end

    def self.npm_test_install
      assert (HOMEBREW_PREFIX/"bin/npm").exist?, "npm must exist"
      assert (HOMEBREW_PREFIX/"bin/npm").executable?, "npm must be executable"
      system "#{HOMEBREW_PREFIX}/bin/npm", "--verbose", "install", "npm@latest"
      system "#{HOMEBREW_PREFIX}/bin/npm", "--verbose", "install", "buffertools"
    end
  end
end
