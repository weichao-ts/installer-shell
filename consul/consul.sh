#! /bin/bash

###
# Install consul.
# Author: rmfish@163.com
# Date: 20150817
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

function install_depends(){
    apt-get install -qq unzip
}



INSTALLER_DIR=/opt/installer
CONSUL_NAME=consul
CONSUL_VERSION=0.5.2
CONSUL_URL=https://dl.bintray.com/mitchellh/consul/${CONSUL_VERSION}_linux_amd64.zip
CONSUL_DIR=$CONSUL_NAME-$CONSUL_VERSION
CONSUL_ZIP=${CONSUL_DIR}.zip
CONSUL_DATA_DIR=/var/consul
CONSUL_DATACENTER_NAME=
CONSUL_RUNNER_USER=admin
CONSUL_RUNNER_HOME=`homedir $CONSUL_RUNNER_USER`
CONSUL_WEB_INSTALL=false
CONSUL_WEB_URL=https://dl.bintray.com/mitchellh/consul/${CONSUL_VERSION}_web_ui.zip
CONSUL_WEB_ZIP=$CONSUL_NAME-${CONSUL_VERSION}_web.zip
CONSUL_WEB_WORKDIR=$CONSUL_RUNNER_HOME/work/consul
CONSUL_MODE=
CONSUL_CONF_DIR=`bashdir $BASH_SOURCE[0]`/conf

function echo_configs(){
    echo.private "INSTALLER_DIR:            ${INSTALLER_DIR}"
    echo.private "CONSUL_NAME:              ${CONSUL_NAME}"
    echo.private "CONSUL_VERSION:           ${CONSUL_VERSION}"
    echo.private "CONSUL_URL:               ${CONSUL_URL}"
    echo.private "CONSUL_DIR:               ${CONSUL_DIR}"
    echo.private "CONSUL_ZIP:               ${CONSUL_ZIP}"
    echo.private "CONSUL_DATA_DIR:          ${CONSUL_DATA_DIR}"
    echo.private "CONSUL_DATACENTER_NAME:   ${CONSUL_DATACENTER_NAME}"
    echo.private "CONSUL_WEB:               ${CONSUL_WEB_INSTALL}"
    echo.private "CONSUL_WEB_URL:           ${CONSUL_WEB_URL}"
    echo.private "CONSUL_MODE:              ${CONSUL_MODE}"
}

function config(){
    read -p " Consul installer location [${INSTALLER_DIR}]:" install
    if [[ $install != "" ]]; then 
        INSTALLER_DIR=$install
    fi 

    read -p " Consul runner user [$CONSUL_RUNNER_USER]:" runner
    if [[ $runner != "" ]]; then 
        CONSUL_RUNNER_USER=$runner
    fi 
   
    read -p " Consul data store location [${CONSUL_DATA_DIR}]:" consul_data_dir
    if [[ $consul_data_dir != "" ]]; then 
        CONSUL_DATA_DIR=$consul_data_dir
    fi 
    
    while [[ $CONSUL_DATACENTER_NAME = "" ]];do
        read -p " Consul datacenter name:" consul_dc_name
        if [[ $consul_dc_name != "" ]]; then 
            CONSUL_DATACENTER_NAME=$consul_dc_name
        fi
    done;

    while [[ $consul_web = "" ]];do
        read -p " Consul start with web console on this server? [Y/n]:" consul_web
        case $consul_web in 
        Y | y) 
            CONSUL_WEB_INSTALL=true;; 
        N | n) 
            CONSUL_WEB_INSTALL=false;;
        *)
            consul_web="" 
            echo.danger " Input only accept Y or N.";;
        esac
    done;

    consul_modes='server bootstrap client'
    echo " Consul mode is: "
    while [[ $mode = "" ]];do
         select mode in $consul_modes;do
             if [ $mode ]; then
                 case $mode in
                 server)
                     CONSUL_MODE=server
                     break;;
                 bootstrap)
                     CONSUL_MODE=bootstrap
                     break;;
                 client)
                     CONSUL_MODE=client
                     break;;
                 *)
                     mode="";
                     echo.danger "Please input the numbe of selector.";;
                 esac
             else
                 mode="";
                 echo.danger "Please input the numbe of selector."
             fi
         done
    done

    IPs=`ifconfig | awk '/inet addr/{print substr($2,6)}'`
    echo " Consul bind adds:"
    select ip in $IPs;do
        if [ $ip ]; then
           BIND_ADDR=$ip
           break
        fi
    done    

    mkdir -p $INSTALLER_DIR
    mkdir -p $CONSUL_DATA_DIR

#    echo_configs;
}

function install_consul(){
    if [ ! -d $INSTALLER_DIR/$CONSUL_DIR ]; then
        require $INSTALLER_DIR/$CONSUL_ZIP $CONSUL_URL
        if [ ! -f $INSTALLER_DIR/$CONSUL_ZIP ]; then
            unzip $INSTALLER_DIR/$CONSUL_ZIP -d $INSTALLER_DIR/$CONSUL_DIR
        fi
    fi

    echo.info " Install consul to /usr/local/bin/$CONSUL_NAME"    
    cp $INSTALLER_DIR/$CONSUL_DIR/$CONSUL_NAME /usr/local/bin


  }

function install_consul_web(){
    if [ $CONSUL_WEB_INSTALL = "true" ]; then
        mkdir -p $CONSUL_RUNNER_HOME/work/consul
        if [ ! -d $INSTALLER_DIR/$CONSUL_DIR/dist ]; then
            require $INSTALLER_DIR/$CONSUL_WEB_ZIP $CONSUL_WEB_URL
            if [ ! -f $INSTALLER_DIR/$CONSUL_WEB_ZIP ]; then
                unzip $INSTALLER_DIR/$CONSUL_WEB_ZIP -d $INSTALLER_DIR/$CONSUL_DIR
            fi
        fi
        echo.warning " Consul web application location is $CONSUL_RUNNER_HOME/work/consul"
        su $CONSUL_RUNNER_USER -c "mkdir -p $CONSUL_WEB_WORKDIR"
        cp -R $INSTALLER_DIR/$CONSUL_DIR/dist/* $CONSUL_WEB_WORKDIR   
    fi
}

function setconfig(){
# echo $1 $2 $3
if [ $2 = "true" ] || [ $2 = "false" ]; then
    sed -i "s|.*\"$1\".*|\"$1\":$2,|g" $3
else
    sed -i "s|.*\"$1\".*|\"$1\":\"$2\",|g" $3
fi
}


function config_consul(){
    CONSUL_CONFIG_LOCATION=/etc/consul.d
    CONSUL_CONFIG_FILE=$CONSUL_CONFIG_LOCATION/config.json
    mkdir -p $CONSUL_CONFIG_LOCATION
    cp $CONSUL_CONF_DIR/config.template $CONSUL_CONFIG_FILE
    echo.info " Create consul configs. [$CONSUL_CONFIG_FILE]"

    if [ $CONSUL_MODE = "bootstrap" ]; then
        setconfig bootstrap true $CONSUL_CONFIG_FILE
        setconfig server true $CONSUL_CONFIG_FILE
        setconfig datacenter $CONSUL_DATACENTER_NAME $CONSUL_CONFIG_FILE
        setconfig data_dir $CONSUL_DATA_DIR $CONSUL_CONFIG_FILE
        setconfig bind_addr $BIND_ADDR $CONSUL_CONFIG_FILE
    fi
    if [ $CONSUL_MODE = "server" ]; then
        setconfig bootstrap false $CONSUL_CONFIG_FILE
        setconfig server true $CONSUL_CONFIG_FILE
        setconfig datacenter $CONSUL_DATACENTER_NAME $CONSUL_CONFIG_FILE
        setconfig data_dir $CONSUL_DATA_DIR $CONSUL_CONFIG_FILE
        setconfig bind_addr $BIND_ADDR $CONSUL_CONFIG_FILE
    fi
    if [ $CONSUL_MODE = "client" ]; then
        setconfig bootstrap false $CONSUL_CONFIG_FILE
        setconfig server false $CONSUL_CONFIG_FILE
        setconfig datacenter $CONSUL_DATACENTER_NAME $CONSUL_CONFIG_FILE
        setconfig data_dir $CONSUL_DATA_DIR $CONSUL_CONFIG_FILE
        setconfig bind_addr $BIND_ADDR $CONSUL_CONFIG_FILE
    fi
    if [ $CONSUL_WEB_INSTALL = true ]; then
        setconfig ui_dir $CONSUL_WEB_WORKDIR $CONSUL_CONFIG_FILE
    else
        sed -i 's/.*"ui_dir".*//g' $CONSUL_CONFIG_FILE
    fi
    
    CONSUL_INIT_FILE=/etc/init/consul.conf
    echo.info " Set consul init conf. [$CONSUL_INIT_FILE]"
    cp $CONSUL_CONF_DIR/init.conf $CONSUL_INIT_FILE 

}

install_depends
config
install_consul
install_consul_web
config_consul
