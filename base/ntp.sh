#! /bin/bash

###
# TODO: The introduction of this shell.
# Author: rmfish@163.com
# Date: 20150811
# Version: 1
###

USER=`whoami`

if [ $USER != "root" ];then
    echo "This command shoud run as administrator (user "root"), use "sudo addadmin.sh" please!"
    exit
fi

# Set the timezone as Shanghai
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# Install the ntpdate and set a ntpserver
apt-get update && apt-get install -y ntpdate
ntpdate -u pool.ntp.org
date

