#! /bin/bash

###
# TODO: The introduction of this shell.
# Author: rmfish@163.com
# Date: 20150811
# Version: 1
###

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

if ! command_exists echo.info; then
	echo "The basic cmd is not installed. run 'sudo sh base/base.sh' please!"
	exit
fi


USER=`whoami`
BASH_NAME=$(basename $BASH_SOURCE)
BASH_DIR=`bashdir ${BASH_SOURCE[0]}`

echo.private "This is a template shell, created by rmfish."
echo.info "Shell path is: '$BASH_DIR/$BASH_NAME'"

if [ $USER != "root" ];then
    echo.danger 'This command shoud run as administrator (user "root"), use "sudo '${BASH_NAME}'" please!'
    exit
fi
