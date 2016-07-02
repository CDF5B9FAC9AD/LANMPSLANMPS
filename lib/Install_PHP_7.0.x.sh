
PHP7_PATH=${IN_DIR}/php
tmp_configure=""
if [ $SERVER == "nginx" ]; then
	tmp_configure="--enable-fpm --with-fpm-user=www --with-fpm-group=www"
else
	tmp_configure="--with-apxs2=${IN_DIR}/apache/bin/apxs"
fi

echo "php-${VERS['php7.0.x']}.tar.gz"

cd $IN_DOWN
tar zxvf php-${PHP_VER}.tar.gz
cd php-${PHP_VER}/
./configure --prefix="${PHP7_PATH}" \
--with-config-file-path="${PHP7_PATH}" \
--with-curl \
--with-freetype-dir \
--with-gd \
--with-gettext \
--with-iconv-dir \
--with-jpeg-dir \
--with-kerberos \
--with-libdir=lib64 \
--with-libxml-dir \
--with-mysqli \
--with-openssl \
--with-pcre-regex \
--with-pdo-mysql \
--with-pdo-sqlite \
--with-pear \
--with-png-dir \
--with-mcrypt \
--with-xmlrpc \
--with-xsl \
--with-zlib \
--with-mhash \
--with-xmlrpc \
--without-gdbm \
--without-pear \
--enable-ftp \
--enable-bcmath \
--enable-libxml \
--enable-inline-optimization \
--enable-gd-native-ttf \
--enable-mbregex \
--enable-mbstring \
--enable-opcache \
--enable-pcntl \
--enable-shmop \
--enable-soap \
--enable-sockets \
--enable-sysvsem \
--enable-session \
--enable-xml \
--enable-zip \
--disable-rpath \
--disable-fileinfo $tmp_configure
#make ZEND_EXTRA_LIBS='-liconv'
make
make install

if [ -e /usr/bin/php ]; then
#rm -f "/usr/bin/php"
    ln -s "${PHP7_PATH}/bin/php" /usr/bin/php7
    ln -s "${PHP7_PATH}/bin/phpize" /usr/bin/phpize7
    ln -s "${PHP7_PATH}/sbin/php-fpm" /usr/bin/php-fpm7
else
    ln -s "${PHP7_PATH}/bin/php" /usr/bin/php
    ln -s "${PHP7_PATH}/bin/phpize" /usr/bin/phpize
    ln -s "${PHP7_PATH}/sbin/php-fpm" /usr/bin/php-fpm
fi

php_ini="${PHP7_PATH}/php.ini"
echo "Copy new php configure file. $php_ini "
cp php.ini-production $php_ini

echo "Modify php.ini......"
sed -i 's/post_max_size = 8M/post_max_size = 50M/g' $php_ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' $php_ini
sed -i 's/;date.timezone =/date.timezone = PRC/g' $php_ini
sed -i 's/short_open_tag = Off/short_open_tag = On/g' $php_ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' $php_ini
sed -i 's/;cgi.fix_pathinfo=0/cgi.fix_pathinfo=0/g' $php_ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' $php_ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' $php_ini
sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' $php_ini
sed -i 's:mysql.default_socket =:mysql.default_socket ='$IN_DIR'/mysql/data/mysql.sock:g' $php_ini
sed -i 's:pdo_mysql.default_socket.*:pdo_mysql.default_socket ='$IN_DIR'/mysql/data/mysql.sock:g' $php_ini
sed -i 's/expose_php = On/expose_php = Off/g' $php_ini

sed -i 's#\[opcache\]#\[opcache\]\nzend_extension=opcache.so#g' $php_ini
sed -i 's/;opcache.enable=0/opcache.enable=1/g' $php_ini
sed -i 's/;opcache.enable_cli=0/opcache.enable_cli=1/g' $php_ini
sed -i 's/;opcache.memory_consumption=64/opcache.memory_consumption=128/g' $php_ini
sed -i 's/;opcache.interned_strings_buffer=4/opcache.interned_strings_buffer=8/g' $php_ini
sed -i 's/;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/g' $php_ini
sed -i 's/;opcache.revalidate_freq=2/opcache.revalidate_freq=60/g' $php_ini
sed -i 's/;opcache.fast_shutdown=0/opcache.fast_shutdown=1/g' $php_ini
sed -i 's/;opcache.save_comments=1/opcache.save_comments=0/g' $php_ini


ln -s $php_ini $IN_DIR/etc/php.ini

#PHP-FPM
if [ $SERVER == "nginx" ]; then

echo "MV php-fpm.conf file"
conf=$IN_DIR/php/etc/php-fpm.conf;
mv $IN_DIR/php/etc/php-fpm.conf.default $conf

sed -i 's:;pid = run/php-fpm.pid:pid = run/php-fpm.pid:g' $conf
sed -i 's:;error_log = log/php-fpm.log:error_log = '"$IN_WEB_LOG_DIR"'/php-fpm.log:g' $conf
sed -i 's:;log_level = notice:log_level = notice:g' $conf

conf=$IN_DIR/php/etc/php-fpm.d/www.conf;
mv $IN_DIR/php/etc/php-fpm.d/www.conf.default $conf
sed -i 's:pm.max_children = 5:pm.max_children = 10:g' $conf
sed -i 's:pm.max_spare_servers = 3:pm.max_spare_servers = 6:g' $conf
sed -i 's:;request_terminate_timeout = 0:request_terminate_timeout = 100:g' $conf
sed -i 's/127.0.0.1:9000/127.0.0.1:9950/g' $conf

ln -s $IN_DIR/php/etc/php-fpm.conf $IN_DIR/etc/php-fpm.conf

echo "Copy php-fpm init.d file......"
cp "${IN_DOWN}/php-${PHP_VER}/sapi/fpm/init.d.php-fpm" $IN_DIR/action/php-fpm
chmod +x $IN_DIR/action/php-fpm
if [ $ETC_INIT_D_LN = 1 ]; then
	ln -s $IN_DIR/action/php-fpm $IN_DIR/init.d/php-fpm
fi
if [ ! $IN_DIR = "/www/lanmps" ]; then
	sed -i "s:/www/lanmps:$IN_DIR:g" $IN_DIR/action/php-fpm
fi



fi
#PHP-FPM
unset php_ini conf