#! /bin/bash

###
# Copy the basic commond to the $PATH[/usr/bin].
# Author: rmfish@163.com
# Date: 20150811
# Version: 1
###

USER=`whoami`
BASH_NAME=$(basename $BASH_SOURCE)


current_path() {
    SOURCE=${BASH_SOURCE[0]}
    DIR=$( dirname "$SOURCE" )
    while [ -h "$SOURCE" ]
    do
        SOURCE=$(readlink "$SOURCE")
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
        DIR=$( cd -P "$( dirname "$SOURCE"  )" && pwd )
    done
    DIR=$( cd -P "$( dirname "$SOURCE" )" && pwd )
    echo $DIR
}

BASH_DIR=$(current_path)

if [ $USER != "root" ];then
	echo -e '\033[31m This command shoud run as administrator (user "root"), use "sudo '${BASH_NAME}'" please! \033[0m'
    exit
fi


for cmd in `ls $BASH_DIR/basic/`
do
	echo "Copy $cmd to /usr/bin"
	cp $BASH_DIR/basic/$cmd /usr/bin/
done
#cp $BASH_DIR/basic/* /usr/bin/
