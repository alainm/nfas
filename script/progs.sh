#!/bin/bash
# set -x

# Script to install and configure most used programs
# Usage: /script/ssh.sh <cmd>
# <cmd>: --first       first instalation
#        --hostname    Hostname has changed (used by git)
#        --email       Email has changed (used by git)
#        <nothing>     Interactive mode, used by nfas menu

#=======================================================================
# Process command line
CMD=$1
# Auxiliary Functions
. /script/functions.sh
# Read previous configurations if they exist
. /script/info/distro.var
. /script/info/hostname.var
. /script/info/email.var
VAR_FILE="/script/info/progs.var"
[ -e $VAR_FILE ] && . $VAR_FILE
TITLE="NFAS - Configuration and Instalation: Utilities"

#-----------------------------------------------------------------------
# Install pre-configured programs
function ProgsInstall(){
  local MSG1=""
  if [ "$CMD" == "--first" ]; then
    MSG="Install"
    NODE_MSG=" (Mandatory)"
    NODE_OPT=YES
  else
    MSG="Install/Config"
    NODE_MSG=""
    NODE_OPT=NO
  fi
  local OPTIONS=$(whiptail --title "$TITLE"                            \
    --checklist "\nSelect the programs that you need to $MSG:" 22 75 2 \
    'Node'     "  Node.js $NODE_MSG" $NODE_OPT       \
    'MongoDB'  "  DtataBase"    NO                   \
    3>&1 1>&2 2>&3)
    # 'Rabbit'   "  RabitMQ - AMQP queue server"  NO   \
  if [ $? == 0 ]; then
    # Remove quotation marks and force Node.js option
    OPTIONS=$(echo $OPTIONS | tr -d '\"')
    if [ "$CMD" == "--first" ]; then
      echo $OPTIONS | grep "Node"; [ $? -ne 0 ] && OPTIONS="Node $OPTIONS"
    fi
    #--- Install selected programs
    echo "Opt list=[$OPTIONS]"
    for OPT in $OPTIONS; do
      echo "Instaling: $OPT"
      case $OPT in
        "Node")
          /script/prog-node.sh $CMD
        ;;
        "MongoDB")
          /script/prog-mongo.sh $CMD
        ;;
        "Rabbit")
          /script/prog-rabit.sh $CMD
        ;;
        "MQTT")
          echo "Install MQTT..."
        ;;
      esac
    done # for OPT
  fi
}
#-----------------------------------------------------------------------
# main()

if [ "$CMD" == "--first" ]; then
  #--- First run, select programs to install
  /script/prog-git.sh --first
  ProgsInstall

#-----------------------------------------------------------------------
elif [ "$CMD" == "--hostname" ]; then
  /script/prog-git.sh --hostname

#-----------------------------------------------------------------------
elif [ "$CMD" == "--email" ]; then
  /script/prog-git.sh --email

#-----------------------------------------------------------------------
else
  #--- Select programs to install
  ProgsInstall
fi
#-----------------------------------------------------------------------
