#!/bin/bash
# set -x

# CAUTION: not tested, problem reconfiguring (removed from menu)

# Script for installing and configuring RabbitMQ
# Usage: /script/prog-rabbit.sh <cmd>
# <cmd>: --first       First install
#        <nothing>     Interative mode, used by menu nfas

# Management: https://www.rabbitmq.com/management.html
# Tunnel: ssh nfas -L 15672:192.168.0.159:15672 -N
# http://localhost:15672  =>  User/passwd: admin/admin

#=======================================================================
# Process command line
CMD=$1
# Auxiliary Functions
. /script/functions.sh
# Read previous configurations if they exist
. /script/info/distro.var
VAR_FILE="/script/info/rabit.var"
CONF_FILE="/etc/rabbitmq/rabbitmq.config"
TITLE="NFAS - RabbitMQ configuration"

#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# Ask for the TCP port to use for RabbitMQ
# Returns: 0=ok, 1=Abort
function AskRabbitPort(){
  local ERR_ST=""
  local PORT_TMP
  # Save current port
  PORT_TMP=$RABT_PORT
  # loop, only exists with Ok or Abort
  while true; do
    MSG="\nAccess port for RabbitMQ, internal use only (default 5672)"
    MSG+="\n\n<Enter> to keep previous one being shown\n"
    # Acrescenta mensagem de erro
    MSG+="\n$ERR_ST"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    PORT_TMP=$(whiptail --title "$TITLE" --inputbox "$MSG" 14 74 $PORT_TMP 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operation aborted!"
      return 1
    fi
    # Validate port
    if [[ $PORT_TMP =~ [0-9]* ]] && [ $PORT_TMP -gt 0 ] && [ $PORT_TMP -lt 65536 ]; then
      # Port accepted
      echo "RabbitMQ service port ok: $PORT_TMP"
      # save result
      RABT_PORT=$PORT_TMP
      return 0
    else
      ERR_ST="Service port invalid, Please try again"
    fi
  done
}

#-----------------------------------------------------------------------
# Ask how much memory to use for RabbitMQ
# Returns: 0=ok, 1=Abort
function AskRabbitMemory(){
  local ERR_ST=""
  local MEM_TMP
  # Save current port
  MEM_TMP=$RABT_MEM
  # loop, only exists with Ok or Abort
  while true; do
     MSG="\nWhat  >Porcentage< of memory should RabbitMQ use?"
    MSG+="\n  (we recommend 20%, upper limit is 30% greater)"
    MSG+="\n\n<Enter> to keep previous one being shown\n"
    # Add error message
    MSG+="\n$ERR_ST"
    # whiptail usage: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    MEM_TMP=$(whiptail --title "$TITLE" --inputbox "$MSG" 14 74 $MEM_TMP 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operation aborted!"
      return 1
    fi
    # Validate value
    if [[ $MEM_TMP =~ [0-9]* ]] && [ $MEM_TMP -ge 10 ] && [ $MEM_TMP -le 80 ]; then
      # Port accepted
      echo "Memory share for RabbitMQ ok: $MEM_TMP"
      # save result
      RABT_MEM=$MEM_TMP
      return 0
    else
      ERR_ST="Invalid value, must be between 10 and 80 (%)"
    fi
  done
}

#-----------------------------------------------------------------------
# Install RabbitMQ
# https://www.digitalocean.com/community/tutorials/how-to-install-and-manage-rabbitmq
# TODO: Search for newest version, CAUTION with the digit after the version number
function RabbitInstall(){
  #set -x
  local PKT_VER PKT_FILE PKT_URL
#  if ! which rabbitmq-server >/dev/null; then
    # Not installed
    if [ "$DISTRO_NAME" == "CentOS" ]; then
      if [ "$DISTRO_VERSION" == "6" ]; then
        # Latest vertion for this version of Erlang
        PKT_VER="3.2.2" # "3.5.7"
        # Add and enable relevant application repositories:
        # Note: We are enabling third party remi package repositories.
        wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
        sudo rpm -Uvh remi-release-6*.rpm
      elif [ "$DISTRO_VERSION" == "7" ]; then
        echo "CentOS 7 has no tutorial..."
      fi
      # Finally, download and install Erlang:
      yum install -y erlang
      PKT_FILE="rabbitmq-server-$PKT_VER-1.noarch.rpm"
      PKT_URL="http://www.rabbitmq.com/releases/rabbitmq-server/v$PKT_VER"
      # Download the latest RabbitMQ package using wget:
      wget $PKT_URL/$PKT_FILE
      # Add the necessary keys for verification:
      rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
      # Install the .RPM package using YUM:
      yum install $PKT_FILE
    else
      echo "Ubuntu..."
    fi
    # Enabling the Management Console, port=15672
    rabbitmq-plugins enable rabbitmq_management
    # RabbitMQ runs with user rabbitmq
    chown rabbitmq:rabbitmq /etc/rabbitmq/enabled_plugins
    # Create new user admin/admin
    # http://stackoverflow.com/questions/22850546/cant-access-rabbitmq-web-management-interface-after-fresh-install
    rabbitmqctl add_user admin admin
    rabbitmqctl set_user_tags admin administrator
    rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
    # Instala serviço
    chkconfig rabbitmq-server on
    service rabbitmq-server start
    # Copy the example file...
#  fi
  #set +x
}

#-----------------------------------------------------------------------
# Configure RabitMQ
# File is created every time, changes will be lost
function RabbitConfig(){
  echo -e "%%\n%%{NFAS-RabitMQ} Atention: changes to this file will be lost when reconfiguring\n%%" 2>/dev/null > $CONF_FILE
  echo -e "[\n  {rabbit, ["                                2>/dev/null >> $CONF_FILE
  echo -e "      {tcp_listeners, [$RABT_PORT]},"           2>/dev/null >> $CONF_FILE
  echo -e "      {vm_memory_high_watermark, 0.$RABT_MEM}"  2>/dev/null >> $CONF_FILE
  echo -e "  ]}\n]."                                       2>/dev/null >> $CONF_FILE
  # RabbitMQ runs with user rabbitmq
  chown rabbitmq:rabbitmq $CONF_FILE
  # restart to force changes
  service rabbitmq-server reload
}

#-----------------------------------------------------------------------
# Setup Menu
# TODO: configurar "vm_memory_high_watermark" default de 40% para 20%
function RabbitMenu(){
  local MSG MENU_IT MN_PORT MN_MEM
  # Cancel button message
  # [ "$CMD" == "--first" ] && CAN_MSG="End" || CAN_MSG="Retornar"
  # Loop do Menu principal interativo
  while true; do
    MN_PORT="Access port                CURRENT=$RABT_PORT"
     MN_MEM="Memory usage, lower limit  CURRENT=$RABT_MEM%"
    MENU_IT=$(whiptail --title "$TITLE" --fb --cancel-button "End" \
        --menu "\nConfiguration options:" 18 78 2  \
        "1" "$MN_PORT"                             \
        "2" "$MN_MEM"                              \
        3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
        echo "Finished"
        return 0
    fi
    # Funções que ficam em Procedures
    [ "$MENU_IT" == "1" ] && AskRabbitPort
    [ "$MENU_IT" == "2" ] && AskRabbitMemory
  done
}

#-----------------------------------------------------------------------
# Read Mosquitto saved Vars
# if not set, provide reasonable defaults
function ReadRabbitVars(){
  # Erase previous values ans set compatibility
  RABT_PORT="5672"
  RABT_MEM="20"
  # Read already existing file
  [ -e $VAR_FILE ] && . $VAR_FILE
}

#-----------------------------------------------------------------------
# Save Setup variables
# These will be used by other modules end for future iteraction
function SaveRabbitVars(){
  echo "RABT_PORT=\"$RABT_PORT\""                  2>/dev/null >  $VAR_FILE
  echo "RABT_MEM=\"$RABT_MEM\""                    2>/dev/null >> $VAR_FILE
}

#=======================================================================
# main()

# Read Variables and set defaults
ReadRabbitVars

#-----------------------------------------------------------------------
if [ "$CMD" == "--first" ]; then
  # same as not --first
  RabbitInstall
  RabbitMenu
  RabbitConfig

#-----------------------------------------------------------------------
else
  #--- Set options and install
set -x
  RabbitInstall
  RabbitMenu
  RabbitConfig

fi
#-----------------------------------------------------------------------
SaveRabbitVars
#=======================================================================

