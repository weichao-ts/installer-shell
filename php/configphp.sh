#! /bin/bash

###
# TODO: The introduction of this shell.
# Author: rmfish@163.com
# Date: 20150811
# Version: 1
###

USER=`whoami`
BASH_NAME=$(basename $BASH_SOURCE)
BASH_DIR=`bashdir ${BASH_SOURCE[0]}`

if [ $USER != "root" ];then
        echo.danger 'This command shoud run as administrator (user "root"), use "sudo '${BASH_NAME}'" please!'
    exit
fi

PHP_DIR=$1
DEFAULT_PHP_DIR=/usr/local/php
INSTALLER_DIR=/opt/installer
PHP_CONFIG_DEFAULT=$BASH_DIR/conf
PHP_RUNNER_USER=admin
PHP_RUNNER_GROUP=admin


if [ ! -n "$PHP_DIR" ]; then
	PHP_DIR=$DEFAULT_PHP_DIR
	if [ -d $PHP_DIR ]; then
		echo.warning ' The PHP_DIR is not set. use the default php_dir['${PHP_DIR}'].'
	fi
fi	

if [ ! -d $PHP_DIR ]; then
	echo.warning ' The PHP_DIR is not set or the dir is not exist. use "'${BASH_NAME}' PHP_DIR" please!'
	exit
fi	

#config php
if [ ! -L /usr/bin/php ]; then
	ln -s ${PHP_DIR}/bin/php /usr/bin/php
fi

if [ ! -L /usr/bin/phpize ]; then
	ln -s ${PHP_DIR}/bin/phpize /usr/bin/phpize
fi

if [ ! -L /usr/bin/php ]; then
	ln -s ${PHP_DIR}/sbin/php-fpm /usr/bin/php-fpm
fi

mkdir -p ${PHP_DIR}/etc


echo.info ' Set '${PHP_DIR}'/etc/php.ini'

if [ ! -f ${PHP_DIR}/etc/php.ini ]; then
	cp $PHP_CONFIG_DEFAULT/php.ini ${PHP_DIR}/etc/php.ini
fi

if [ -f ${PHP_DIR}/etc/php.ini ]; then
		sed -i 's@expose_php = On@expose_php = Off@g' ${PHP_DIR}/etc/php.ini
		sed -i 's/post_max_size = 8M/post_max_size = 50M/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/;date.timezone =/date.timezone = PRC/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/short_open_tag = Off/short_open_tag = On/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/; cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/; cgi.fix_pathinfo=0/cgi.fix_pathinfo=0/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/max_execution_time = 30/max_execution_time = 300/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/register_long_arrays = On/;register_long_arrays = On/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/magic_quotes_gpc = On/;magic_quotes_gpc = On/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/disable_functions =.*/disable_functions = passthru,system,chroot,chgrp,chown,proc_open,proc_get_status,ini_alter,ini_restore,dl,pfsockopen,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsockopen/g' ${PHP_DIR}/etc/php.ini

		#enable opcache
		sed -i '/;opcache.enable=0/i\zend_extension=opcache.so' ${PHP_DIR}/etc/php.ini
		sed -i 's/;opcache.enable=0/opcache.enable=1/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/;opcache.enable_cli=0/opcache.enable_cli=1/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/;opcache.memory_consumption=64/opcache.memory_consumption=128/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/;opcache.interned_strings_buffer=4/opcache.interned_strings_buffer=8/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/;pcache.max_accelerated_files=2000/pcache.max_accelerated_files=4000/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/;opcache.revalidate_freq=2/opcache.revalidate_freq=60/g' ${PHP_DIR}/etc/php.ini
		sed -i 's/;opcache.fast_shutdown=0/opcache.fast_shutdown=1/g' ${PHP_DIR}/etc/php.ini
fi


echo.info ' Set '${PHP_DIR}'/etc/php-fpm.conf'
if [ ! -f ${PHP_DIR}/etc/php-fpm.conf ]; then
	if [ -f $PHP_CONFIG_DEFAULT/php-fpm.conf ]; then
		cp $PHP_CONFIG_DEFAULT/php-fpm.conf ${PHP_DIR}/etc/
	else
cat >${PHP_DIR}/etc/php-fpm.conf<<EOF
[global]
pid =  /var/log/php/php-fpm.pid
error_log = /var/log/php/php-fpm.log
log_level = notice

[www]
listen = /var/run/php5-fpm.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = ${PHP_RUNNER_USER}
listen.group = ${PHP_RUNNER_GROUP}
listen.mode = 0666
user = ${PHP_RUNNER_USER}
group = ${PHP_RUNNER_GROUP}
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = /var/log/php/slow.log
EOF
	
	fi
fi

mkdir -p /var/log/php


echo.info "  Set admin nopasswd run php service."
PHP_SUDOER=/etc/sudoers.d/adminphp
cat >$PHP_SUDOER<<EOF
${PHP_RUNNER_USER} ALL=(ALL) NOPASSWD:/usr/bin/service php-fpm restart
EOF
chmod 0440 $PHP_SUDOER

