class MakensisAT246 < Formula
  desc "System to create Windows installers"
  homepage "https://nsis.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/nsis/NSIS%202/2.46/nsis-2.46-src.tar.bz2"
  sha256 "f5f9e5e22505e44b25aea14fe17871c1ed324c1f3cc7a753ef591f76c9e8a1ae"
  license "Zlib"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "e189ee20201ab5362625cb677875aed597ad56b85da29ca4b67dbe21396c9f4a"
    sha256 cellar: :any_skip_relocation, big_sur:       "aa8a346937316765bf9ffe7d532b08212fab4ae697aad7e23185baeabe280249"
    sha256 cellar: :any_skip_relocation, catalina:      "889d630bf8637f68e90a9591a373ee44bde8d9d6a9395171e024fdced27f26ef"
    sha256 cellar: :any_skip_relocation, mojave:        "b40f5a388f0dddeb2c3d274bdc43fbba6cc0a9f613d056f0981bc60350252448"
    sha256 cellar: :any_skip_relocation, high_sierra:   "fe92934c874a27ead142b769d1c1258c6fd3baa66f2f005cad3f57ccd759734f"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "39ae544951ae954b512686ba78c4f191ca29bd0de88a427bf8c39c49816f01b6"
  end

  option "with-advanced-logging", "Enable advanced logging of all installer actions"
  option "with-large-strings", "Enable strings up to 8192 characters instead of default 1024"
  option "with-debug", "Build executables with debugging information"

  depends_on "scons" => :build

  resource "nsis" do
    url "https://downloads.sourceforge.net/project/nsis/NSIS%202/2.46/nsis-2.46.zip"
    sha256 "ced6561f8aed81c8f3d6bc5a33684e03ca36a618110c0a849880c703337f26cc"
  end

  # scons appears to have no builtin way to override the compiler selection,
  # and the only options supported on OS X are 'gcc' and 'g++'.
  # Use the right compiler by forcibly altering the scons config to set these
  patch :DATA

  def install
    args = [
      "PREFIX_DOC=#{share}/nsis/Docs",
      "SKIPUTILS=Makensisw,NSIS Menu,zip2exe",
      # Don't strip, see https://github.com/Homebrew/homebrew/issues/28718
      "STRIP=0",
      "VERSION=#{version}",
    ]

    args << "NSIS_CONFIG_LOG=yes" if build.with? "advanced-logging"
    args << "NSIS_MAX_STRLEN=8192" if build.with? "large-strings"
    args << "DEBUG=1" if build.with? "debug"

    system "scons", "makensis", *args

    install_path = if build.with? "debug"
      "build/udebug/makensis/makensis"
    else
      "build/urelease/makensis/makensis"
    end

    bin.install install_path
    (share/"nsis").install resource("nsis")
  end

  test do
    system "#{bin}/makensis", "-VERSION"
    system "#{bin}/makensis", "-HDRINFO"
    system "#{bin}/makensis", "#{share}/nsis/Examples/bigtest.nsi", "-XOutfile /dev/null"
  end
end

__END__
diff --git a/SCons/config.py b/SCons/config.py
index a344456..37c575b 100755
--- a/SCons/config.py
+++ b/SCons/config.py
@@ -1,3 +1,5 @@
+import os
+
 Import('defenv')

 ### Configuration options
@@ -440,6 +442,9 @@ Help(cfg.GenerateHelpText(defenv))
 env = Environment()
 cfg.Update(env)

+defenv['CC'] = os.environ['CC']
+defenv['CXX'] = os.environ['CXX']
+
 def AddValuedDefine(define):
   defenv.Append(NSIS_CPPDEFINES = [(define, env[define])])
