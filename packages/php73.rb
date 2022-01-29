require 'package'

class Php73 < Package
  description 'PHP is a popular general-purpose scripting language that is especially suited to web development.'
  homepage 'http://www.php.net/'
  @_ver = '7.3.33'
  version @_ver
  license 'PHP-3.01'
  compatibility 'all'
  source_url "https://www.php.net/distributions/php-#{@_ver}.tar.xz"
  source_sha256 '166eaccde933381da9516a2b70ad0f447d7cec4b603d07b9a916032b215b90cc'

  binary_url({
    aarch64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/php73/7.3.33_armv7l/php73-7.3.33-chromeos-armv7l.tar.xz',
     armv7l: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/php73/7.3.33_armv7l/php73-7.3.33-chromeos-armv7l.tar.xz',
       i686: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/php73/7.3.33_i686/php73-7.3.33-chromeos-i686.tar.xz',
     x86_64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/php73/7.3.33_x86_64/php73-7.3.33-chromeos-x86_64.tar.xz',
  })
  binary_sha256({
    aarch64: '3b29987c24ed7d47d97152df1ba7915b37fde7c0a4959a003c90691853a2bfae',
     armv7l: '3b29987c24ed7d47d97152df1ba7915b37fde7c0a4959a003c90691853a2bfae',
       i686: '914661dbbce0d93271fc6fa072164d7c255a21634916054b4df6f931ba43791e',
     x86_64: '332b1b11d789481fc735d59722364772ec68cfc4de6c775a558b45454cb074bb',
  })

  depends_on 'libcurl'
  depends_on 'libgcrypt'
  depends_on 'libjpeg'
  depends_on 'libpng'
  depends_on 'libxpm'
  depends_on 'libxslt'
  depends_on 'libzip'
  depends_on 'exif'
  depends_on 'freetype'
  depends_on 're2c'
  depends_on 'tidy'
  depends_on 'unixodbc'
  depends_on 'py3_pygments'

  def self.preflight
    phpver = `php -v 2> /dev/null | head -1 | cut -d' ' -f2`.chomp
    unless ARGV[0] == 'reinstall' and @_ver == phpver
      abort "PHP version #{phpver} already installed.".lightgreen unless phpver.empty?
    end
  end

  def self.patch
    # Configuration
    system "sed -i 's,;pid = run/php-fpm.pid,pid = #{CREW_PREFIX}/tmp/run/php-fpm.pid,' sapi/fpm/php-fpm.conf.in"
    system "sed -i 's,;error_log = log/php-fpm.log,error_log = #{CREW_PREFIX}/log/php-fpm.log,' sapi/fpm/php-fpm.conf.in"
    system "sed -i 's,include=@php_fpm_sysconfdir@/php-fpm.d,include=#{CREW_PREFIX}/etc/php-fpm.d,' sapi/fpm/php-fpm.conf.in"
    system "sed -i 's,^user,;user,' sapi/fpm/www.conf.in"
    system "sed -i 's,^group,;group,' sapi/fpm/www.conf.in"
    system "sed -i 's,@sbindir@,#{CREW_PREFIX}/bin,' sapi/fpm/init.d.php-fpm.in"
    system "sed -i 's,@sysconfdir@,#{CREW_PREFIX}/etc,' sapi/fpm/init.d.php-fpm.in"
    system "sed -i 's,@localstatedir@,#{CREW_PREFIX}/tmp,' sapi/fpm/init.d.php-fpm.in"
    # Set some sane defaults
    system "sed -i 's,post_max_size = 8M,post_max_size = 128M,' php.ini-development"
    system "sed -i 's,upload_max_filesize = 2M,upload_max_filesize = 128M,' php.ini-development"
    system "sed -i 's,;opcache.enable=0,opcache.enable=1,' php.ini-development"
    # Fix cc: error: ext/standard/.libs/type.o: No such file or directory
    # system "sed -i '98303d' configure"
    # system "sed -i '98295,98296d' configure"
    # Fix /usr/bin/file: No such file or directory
    system 'filefix'
  end

  def self.build
    system "env CFLAGS='-pipe -ltinfo' \
      ./configure \
       --prefix=#{CREW_PREFIX} \
       --docdir=#{CREW_PREFIX}/doc \
       --infodir=#{CREW_PREFIX}/info \
       --libdir=#{CREW_LIB_PREFIX} \
       --localstatedir=#{CREW_PREFIX}/tmp \
       --mandir=#{CREW_MAN_PREFIX} \
       --sbindir=#{CREW_PREFIX}/bin \
       --with-config-file-path=#{CREW_PREFIX}/etc \
       --with-freetype-dir=#{CREW_PREFIX}/include/freetype2/freetype \
       --with-libdir=#{ARCH_LIB} \
       --with-jpeg-dir=#{CREW_PREFIX}/include \
       --with-xpm-dir=#{CREW_PREFIX}/include/X11 \
       --with-kerberos=#{CREW_LIB_PREFIX} \
       --enable-exif \
       --enable-fpm \
       --enable-ftp \
       --enable-mbstring \
       --enable-opcache \
       --enable-pcntl \
       --enable-shared \
       --enable-shmop \
       --enable-sockets \
       --enable-zip \
       --with-bz2 \
       --with-curl \
       --with-gd \
       --with-gettext \
       --with-gmp \
       --with-libzip \
       --with-mysqli \
       --with-openssl \
       --with-pcre-regex \
       --with-pdo-mysql \
       --with-pear \
       --with-readline \
       --with-tidy \
       --with-unixODBC \
       --with-xsl \
       --with-zlib"
    system 'make'
  end

  def self.check
    #system 'make', 'test'
  end

  def self.install
    ENV['CREW_FHS_NONCOMPLIANCE_ONLY_ADVISORY'] = '1'
    reload_constants
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/log"
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/tmp/run"
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/etc/init.d"
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/etc/php-fpm.d"
    system 'make', "INSTALL_ROOT=#{CREW_DEST_DIR}", 'install'
    FileUtils.install 'php.ini-development', "#{CREW_DEST_PREFIX}/etc/php.ini", mode: 0o644
    FileUtils.install 'sapi/fpm/init.d.php-fpm.in', "#{CREW_DEST_PREFIX}/etc/init.d/php-fpm", mode: 0o755
    FileUtils.install 'sapi/fpm/php-fpm.conf.in', "#{CREW_DEST_PREFIX}/etc/php-fpm.conf", mode: 0o644
    FileUtils.install 'sapi/fpm/www.conf.in', "#{CREW_DEST_PREFIX}/etc/php-fpm.d/www.conf", mode: 0o644
    FileUtils.ln_s "#{CREW_PREFIX}/etc/init.d/php-fpm", "#{CREW_DEST_PREFIX}/bin/php7-fpm"

    # clean up some files created under #{CREW_DEST_DIR}. check http://pear.php.net/bugs/bug.php?id=20383 for more details
    FileUtils.mv "#{CREW_DEST_DIR}/.depdb", "#{CREW_DEST_LIB_PREFIX}/php"
    FileUtils.mv "#{CREW_DEST_DIR}/.depdblock", "#{CREW_DEST_LIB_PREFIX}/php"
    FileUtils.rm_rf ["#{CREW_DEST_DIR}/.channels", "#{CREW_DEST_DIR}/.filemap", "#{CREW_DEST_DIR}/.lock", "#{CREW_DEST_DIR}/.registry"]
  end

  def self.postinstall
    puts
    puts 'To start the php-fpm service, execute:'.lightblue
    puts 'php7-fpm start'.lightblue
    puts
    puts 'To stop the php-fpm service, execute:'.lightblue
    puts 'php7-fpm stop'.lightblue
    puts
    puts 'To restart the php-fpm service, execute:'.lightblue
    puts 'php7-fpm restart'.lightblue
    puts
    puts 'To start php-fpm on login, execute the following:'.lightblue
    puts "echo 'if [ -f #{CREW_PREFIX}/bin/php7-fpm ]; then' >> ~/.bashrc".lightblue
    puts "echo '  #{CREW_PREFIX}/bin/php7-fpm start' >> ~/.bashrc".lightblue
    puts "echo 'fi' >> ~/.bashrc".lightblue
    puts 'source ~/.bashrc'.lightblue
  end
end
