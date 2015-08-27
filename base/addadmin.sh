#! /bin/bash

###
# Add admin user and admin group.
# Author: rmfish@163.com
# Date: 20150811
# Version: 1
###

USER=`whoami`
BASH_NAME=$(basename $BASH_SOURCE)

if [ $USER != "root" ];then
        echo -e '\033[31m This command shoud run as administrator (user "root"), use "sudo '${BASH_NAME}'" please! \033[0m'
    exit
fi

echo -e "\033[32m Add the admin group: \033[0m"
groupadd admin

echo -e "\033[32m Add the admin user: \033[0m"
useradd -m admin -g admin

echo -e "\033[32m Change the passwd of admin: \033[0m"
passwd admin
