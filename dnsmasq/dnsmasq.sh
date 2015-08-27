#! /bin/bash

###
# Install the dnsmasq and the manager api
# Author: rmfish@163.com
# Date: 20150811
# Version: 1
###

USER=`whoami`
BASH_NAME=$(basename $BASH_SOURCE)
BASH_DIR=`bashdir ${BASH_SOURCE[0]}`


# Check the permission.
if [ $USER != "root" ];then
	echo.danger ' This command shoud run as administrator (user "root"), use "sudo '${BASH_NAME}'" please!'
    exit
fi


INSTALLER_DIR=/opt/installer
DNSMASQ_RUNNER_USER=admin
USER_HOME="$(eval echo ~"$DNSMASQ_RUNNER_USER")"
DNSMASQ_API_WWW=${USER_HOME}/work/www/dnsmasq-api
DNSMASQ_API_REPO=https://github.com/rmfish/dnsmasq-api.git
DNSMASQ_ZONES_DIR=${USER_HOME}/.dnsmasq/zones
NGINX_DIR=/usr/local/nginx

echo.info " Install the dnsmasq."
apt-get install -y dnsmasq

echo.info " Install dnsmasq-api. [$DNSMASQ_API_WWW]"
su $DNSMASQ_RUNNER_USER -c "mkdir -p $DNSMASQ_API_WWW"

if [ ! -d $DNSMASQ_API_WWW/.git ]; then
    su $DNSMASQ_RUNNER_USER -c "git clone $DNSMASQ_API_REPO $DNSMASQ_API_WWW"
else
    su $DNSMASQ_RUNNER_USER -c "git pull"
fi

## cpoy the dnsmasq conf file
DNSMASQ_CONFIG=/etc/dnsmasq.d/dnsmasq-api.conf
echo.info " Config dnsmasq. [${DNSMASQ_CONFIG}]"
if [ ! -d $DNSMASQ_ZONES_DIR ]; then
    su $DNSMASQ_RUNNER_USER -c "mkdir -p $DNSMASQ_ZONES_DIR"
fi

if [ ! -f /etc/dnsmasq.d/dnsmasq-api.conf ]; then
    cp $BASH_DIR/conf/dnsmasq-d.conf $DNSMASQ_CONFIG
    service dnsmasq restart
fi

## config dnsmasq sudoer file
DNSMASQ_SUDOER=/etc/sudoers.d/dnsmasq
echo.info " Allow dnsmasq-api to reload dnsmasq config. [${DNSMASQ_SUDOER}]"
cat >$DNSMASQ_SUDOER<<EOF
${DNSMASQ_RUNNER_USER} ALL=(ALL) NOPASSWD:/usr/bin/service dnsmasq restart,/usr/bin/service dnsmasq force-reload
EOF
chmod 0440 $DNSMASQ_SUDOER

## config nginx conf, add the  dnsmasq api to manage dnsmasq. 
echo.info " Config nginx. [$NGINX_DIR/conf/apps/dnsmasq-nginx.conf]"
if [ ! -f $NGINX_DIR/conf/apps/dnsmasq-nginx.conf ]; then
    cp $BASH_DIR/conf/dnsmasq-nginx.conf $NGINX_DIR/conf/apps/
    cp $NGINX_DIR/conf/apps/php.conf.default $NGINX_DIR/conf/apps/php.conf
fi

echo.info " Dnsmasq installed."

## get current ip for other server.
IP=`ifconfig eth1 | awk '/inet addr/{print substr($2,6)}'`
if [ -n "$IP" ]; then 
	echo.warning " Config other server's resolv file[/etc/resolv.conf]: nameserver ${IP}"
fi
