#! /bin/bash

###
# Install openjdk
# Author: rmfish@163.com
# Date: 20150824
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

#echo.private "This is a template shell, created by rmfish."
#echo.info "Shell path is: '$BASH_DIR/$BASH_NAME'"

if [ $USER != "root" ];then
    echo.danger 'This command shoud run as administrator (user "root"), use "sudo '${BASH_NAME}'" please!'
    exit
fi

jdk_versions="jdk7 jdk8"
echo " Install OpenJDK: "
while [[ $version = "" ]];do
     select mode in $jdk_versions;do
         if [ $version ]; then
             case $version in
             jdk7)
                 JDK_VERSION=7
                 break;;
             jdk8)
                 JDK_VERSION=8
                 break;;
             *)
                 version="";
                 echo.danger "Please input the numbe of selector.";;
             esac
         else
             version="";
             echo.danger "Please input the numbe of selector."
         fi
     done
done


add-apt-repository ppa:webupd8team/java
apt-get update
apt-get install -y oracle-java${JDK_VERSION}-installer

while [[ $default_java = "" ]];do
    read -p " Set java${JDK_VERSION} as default java? [Y/n]:" default_java
    case $default_java in
    Y | y)
        SET_AS_DEFAULT=true;;
    N | n)
        SET_AS_DEFAULT=false;;
    *)
        default_java=""
        echo.danger " Input only accept Y or N.";;
    esac
done;

if [ ${SET_AS_DEFAULT} = "true" ]; then
    apt-get install oracle-java8-set-default
fi
