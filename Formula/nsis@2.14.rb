class MakensisAT214 < Formula
  desc "System to create Windows installers"
  homepage "https://nsis.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/nsis/NSIS%202/2.14/nsis-2.14-src.tar.bz2"
  sha256 "9aaf85dbf02d8532995550e53ba41f537f6c354357f04a6e9048b143d5f7661f"

  bottle do
    cellar :any_skip_relocation
    sha256 "bd5b875da911a5ff1fbdbe1b80ad21e7c2dc5841cd89ba7b9e1d3e412a029bfd" => :mojave
    sha256 "b656fcbbb32f982ff66c897f8af08b989425f3c375aa96572dde0e00f05cc396" => :high_sierra
    sha256 "bf01aff6fbcda07ab721b743ca044207face08b9e5f200b764efce8d9adb1c37" => :sierra
    sha256 "f4516cec938568eb2bea2b162247a10cbd68dedd85c439f5d77170dbc7c5b81b" => :el_capitan
  end

  # See https://nsis.sourceforge.io/Special_Builds#Advanced_logging
  option "with-advanced-logging", "Enable advanced logging of all installer actions"

  # See https://nsis.sourceforge.io/Special_Builds#Large_strings
  option "with-large-strings", "Enable strings up to 8192 characters instead of default 1024"

  option "debug", "Build executables with debugging information"

  depends_on "mingw-w64" => :build
  depends_on "scons" => :build

  resource "nsis" do
    url "https://downloads.sourceforge.net/project/nsis/NSIS%202/2.14/nsis-2.14.zip"
    sha256 "88195a2a1b1bb65baa8f1efc6e2864ca021ccf95a4fc825c6a9bf354f856eb17"
  end

  # v1.2.8 is outdated, but the last version available as compiled DLL
  resource "zlib-win32" do
    url "https://downloads.sourceforge.net/project/libpng/zlib/1.2.8/zlib128-dll.zip"
    sha256 "a03fd15af45e91964fb980a30422073bc3f3f58683e9fdafadad3f7db10762b1"
  end

  def install
    # requires zlib (win32) to build utils
    resource("zlib-win32").stage do
      @zlib_path = Dir.pwd
    end

    args = [
      "CC=#{ENV.cc}",
      "CXX=#{ENV.cxx}",
      "PREFIX_DOC=#{share}/nsis/Docs",
      "SKIPUTILS=Makensisw,NSIS Menu,zip2exe",
      # Don't strip, see https://github.com/Homebrew/homebrew/issues/28718
      "STRIP=0",
      "VERSION=#{version}",
      "ZLIB_W32=#{@zlib_path}",
    ]

    args << "NSIS_CONFIG_LOG=yes" if build.with? "advanced-logging"
    args << "NSIS_MAX_STRLEN=8192" if build.with? "large-strings"
    args << "DEBUG=1" if build.with? "debug"

    scons "makensis", *args
    bin.install "build/urelease/makensis/makensis"
    (share/"nsis").install resource("nsis")
  end

  test do
    system "#{bin}/makensis", "-VERSION"
    system "#{bin}/makensis", "-HDRINFO"
    system "#{bin}/makensis", "#{share}/nsis/Examples/bigtest.nsi", "-XOutfile /dev/null"
  end
end
