#! /bin/bash

###
# Install the php-fpm 
# Author: rmfish@163.com
# Date: 20150811
# Version: 1
###

USER=`whoami`
BASH_NAME=$(basename $BASH_SOURCE)
BASH_DIR=`bashdir ${BASH_SOURCE[0]}`

if [ $USER != "root" ];then
        echo.danger 'This command shoud run as administrator (user "root"), use "sudo '${BASH_NAME}'" please'
    exit
fi

function install_depends()
{
echo.info " Install the required libs."
echo.info " Update source."
#apt-get -qq update
#for packages in gcc g++ make wget libpcre3 libpcre3-dev libpcrecpp0 openssl libcurl4-openssl-dev;
for packages in gcc g++ make wget libmcrypt-dev libxml2-dev libjpeg62 libjpeg62-dev libjpeg-dev libpng-dev;
do 
	echo.info " Install $packages."
	apt-get install -qq -y  $packages --force-yes;
	#apt-get -fy -qq install;
	#apt-get -y -qq autoremove;
done
#apt-get -y -q install gcc g++ make wget libpcre3 libpcre3-dev libpcrecpp0 openssl libcurl4-openssl-dev
}


INSTALLER_DIR=/opt/installer

#install iconv  iconv有bug，需要使用patch过的，具体是在./srclib/stdio.h:1010  注释掉 _GL_WARN_ON_USE (gets, "gets is a security hole - use fgets instead");
ICONV_SO=libiconv.so
ICONV_NAME=libiconv
ICONV_VERSION=1.14
ICONV_FILE=${ICONV_NAME}-${ICONV_VERSION}
ICONV_TGZ=${ICONV_FILE}.tar.gz
ICONV_URL=http://ftp.gnu.org/pub/gnu/libiconv/${ICONV_TGZ}
ICONV_PREFIX_DIR=/usr/local

function install_iconv()
{
    echo.info " Install the libiconv"
    if [ ! -L $ICONV_PREFIX_DIR/lib/$ICONV_SO ]; then
    	if [ ! -d ${INSTALLER_DIR}/${ICONV_FILE} ]; then
    		require ${INSTALLER_DIR}/${ICONV_TGZ} ${ICONV_URL}
    		tar zxf $INSTALLER_DIR/$ICONV_TGZ -C $INSTALLER_DIR
    	fi	
    	
    	cd $INSTALLER_DIR/$ICONV_FILE
    	
    	echo.info " Install ${ICONV_NAME}[${ICONV_VERSION}]:"
    	./configure --prefix=$ICONV_PREFIX_DIR
    
    	echo.warning "  libiconv stdio.h bugfix."
    	# bugfix
    	sed -i 's/^_GL_WARN_ON_USE (gets, "gets is a security hole - use fgets instead")/\/\/&/' $INSTALLER_DIR/$ICONV_FILE/srclib/stdio.h	
    
    	echo.warning "  make libiconv"
    	if [ $CPU_NUM -gt 1 ];then
    		make -j$CPU_NUM
    	else
    		make
    	fi
    
    	echo.warning "  make installlibiconv."
    	make install
    else
    	echo.warning "  The libiconv has installed on ${ICONV_PREFIX_DIR}/lib/${ICONV_SO}"
    fi
}

PHP_PREFIX_DIR=/usr/local/php
PHP_NAME=php
PHP_VERSION=5.5.17
PHP_FILE=${PHP_NAME}-${PHP_VERSION}
PHP_TGZ=${PHP_FILE}.tar.gz
PHP_URL=http://cn2.php.net/distributions/${PHP_TGZ}
PHP_RUNNER_USER=admin
PHP_RUNNER_GROUP=admin
PHP_RUNNER_HOME=$(eval echo ~"$PHP_RUNNER_USER")

function install_php()
{
    echo.info " Install php-fpm"
    if [ ! -d $PHP_PREFIX_DIR ]; then
    	if [ ! -d ${INSTALLER_DIR}/${PHP_FILE} ]; then
    		require ${INSTALLER_DIR}/${PHP_TGZ} ${PHP_URL}
    		tar zxvf $INSTALLER_DIR/$PHP_TGZ -C $INSTALLER_DIR
    	fi	
    	
    	cd $INSTALLER_DIR/$PHP_FILE
    
    	echo.info " Install ${PHP_NAME}[${PHP_VERSION}]:"
    	
    	./configure --prefix=${PHP_PREFIX_DIR} \
    	--with-config-file-path=${PHP_PREFIX_DIR}/etc \
    		--enable-fpm \
    		--with-fpm-user=${PHP_RUNNER_USER} \
    		--with-fpm-group=${PHP_RUNNER_GROUP} \
    		--with-mysql=mysqlnd \
    		--with-mysqli=mysqlnd \
    		--with-pdo-mysql=mysqlnd \
    		--enable-opcache \
    		--enable-static \
    		--enable-inline-optimization \
    		--enable-sockets \
    		--enable-wddx \
    		--enable-zip \
    		--enable-calendar \
    		--enable-bcmath \
    		--enable-soap \
    		--with-zlib \
    		--with-iconv \
    		--with-gd \
    		--with-xmlrpc \
    		--enable-mbstring \
    		--with-curl \
    		--enable-ftp \
    		--with-mcrypt  \
    		--disable-ipv6 \
    		--disable-debug \
    		--with-openssl \
    		--disable-maintainer-zts \
    		--disable-fileinfo
    
    		CPU_NUM=$(cat /proc/cpuinfo | grep processor | wc -l)
    
    		echo.warning "  make php"
    
    		if [ $CPU_NUM -gt 1 ]; then
    			make ZEND_EXTRA_LIBS='-liconv' -j$CPU_NUM
    		else
    			make ZEND_EXTRA_LIBS='-liconv'
    		fi
    
    		make install
    else
    	echo.warning "  The php has installed on ${PHP_PREFIX_DIR}"
    fi
    
    if [ ! -f /etc/init.d/php-fpm ]; then
    	cp $INSTALLER_DIR/$PHP_FILE/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    	chmod +x /etc/init.d/php-fpm
    fi
}

function config_php()
{
    #config php
    echo.info " Make php cmd link on \$PATH"
    if [ ! -L /usr/bin/php ]; then
    	ln -s ${PHP_PREFIX_DIR}/bin/php /usr/bin/php
    fi
    
    if [ ! -L /usr/bin/phpize ]; then
    	ln -s ${PHP_PREFIX_DIR}/bin/phpize /usr/bin/phpize
    fi
    
    if [ ! -L /usr/bin/php ]; then
    	ln -s ${PHP_PREFIX_DIR}/sbin/php-fpm /usr/bin/php-fpm
    fi
    
    echo.info ' Set '${PHP_PREFIX_DIR}'/etc/php.ini'
    mkdir -p ${PHP_PREFIX_DIR}/etc
    if [ ! -f ${PHP_PREFIX_DIR}/etc/php.ini ]; then
 	if [ -f $BASH_DIR/conf/php.ini ]; then
            cp $BASH_DIR/conf/php.ini ${PHP_PREFIX_DIR}/etc/php.ini
        fi
    else
        echo.danger " The php.ini is exist. [${PHP_PREFIX_DIR}/etc/php.ini]"
    fi
    
    echo.info ' Set '${PHP_PREFIX_DIR}'/etc/php-fpm.conf'
    if [ ! -f ${PHP_PREFIX_DIR}/etc/php-fpm.conf ]; then
    	if [ -f $BASH_DIR/conf/php-fpm.conf ]; then
             cp $BASH_DIR/conf/php-fpm.conf ${PHP_PREFIX_DIR}/etc/
    	fi
    else
         echo.danger " The php-fpm.conf is exists. [${PHP_PREFIX_DIR}/etc/php-fpm.conf]" 
    fi
    
    su $PHP_RUNNER_USER -c " mkdir -p $PHP_RUNNER_HOME/logs/php"
}

function config_suid(){
    echo.info " Set php cmd SUID&SGID[$PHP_PREFIX_DIR/bin/php,phpize ../sbin/php-fpm]"
    chgrp $PHP_RUNNER_GROUP ${PHP_PREFIX_DIR}/bin/php
    chgrp $PHP_RUNNER_GROUP ${PHP_PREFIX_DIR}/sbin/php-fpm
    chgrp $PHP_RUNNER_GROUP ${PHP_PREFIX_DIR}/bin/phpize
    chmod ug+s ${PHP_PREFIX_DIR}/bin/php
    chmod ug+s ${PHP_PREFIX_DIR}/bin/phpize
    chmod ug+s ${PHP_PREFIX_DIR}/sbin/php-fpm
}

function config_sudo()
{
    echo.info " Set nopasswd run php service."
    PHP_SUDOER=/etc/sudoers.d/adminphp
cat >$PHP_SUDOER<<EOF
    ${PHP_RUNNER_USER} ALL=(ALL) NOPASSWD:/usr/bin/service php-fpm restart
EOF
    chmod 0440 $PHP_SUDOER
}

install_depends
install_iconv
install_php
config_php
config_suid

