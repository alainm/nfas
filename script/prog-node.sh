#!/bin/bash
# set -x

# Script for installing and configuring Node.js
# Usage: /script/prog-node.sh <cmd>
# <cmd>: --first       First install
#        <nothing>     Interative mode, used by menu nfas

#=======================================================================
# Process command line
CMD=$1
# Auxiliary Functions
. /script/functions.sh
# Read previous configurations if they exist
. /script/info/distro.var
VAR_FILE="/script/info/progs.var"
[ -e $VAR_FILE ] && . $VAR_FILE
TITLE="NFAS - Installing and Configuring Node.js"

#-----------------------------------------------------------------------
# Verify if a version of Node Exists
function CheckVerNode(){
  local NODE_URL="https://nodejs.org/dist/$1/node-$1-linux-x64.tar.gz"
  if [[ `wget -S --spider $NODE_URL  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
    return 0
  else
    return 1
  fi
}

#-----------------------------------------------------------------------
# Gives the newest version of Node Stable
function GetVerNodeStable(){
  # use WGET with "--no-dns-cache -4" to increase connection speed
  local NEW_NODE=$(wget --quiet --no-dns-cache -4 http://nodejs.org/dist/latest/ -O - | sed -n 's/.*\(node.*linux-x64\.tar\.gz\).*/\1/p' | sed -n 's/node-\(v[0-9\.]*\).*/\1/p')
  echo "$NEW_NODE"
}

#-----------------------------------------------------------------------
# Gives the newest version of Node LTS
# Serachs in table in https://nodejs.org/dist/index.tab
#   ref: https://github.com/nodejs/node/issues/4569#issuecomment-169746908
function GetVerNodeLts(){
  # Download offical versions list, column1: version, column10: lts name,
  #   remove first header line, keep only lines with LTS name, last line, version
  local LTS_NODE=$(wget --quiet --no-dns-cache -4 https://nodejs.org/dist/index.tab -O - | awk '{print $1 "\t" $10}' | tail -n +2 | \
    awk '$2 != "-"' | sort | tail -n 1 | cut -f1)
  echo "$LTS_NODE"
}

#-----------------------------------------------------------------------
# Gives current installed verion of Node
function GetVerNodeAtual(){
  if which node >/dev/null; then
    echo $(node -v)
  else
    echo ""
  fi
}

#-----------------------------------------------------------------------
# Procedure to install Node.js (latest)
# site: https://nodejs.org/dist/v4.2.6/node-v4.2.6-linux-x64.tar.gz
# Usage: NodeInstall <versão>
function NodeInstall(){
  # Location and name of file for the requested version
  local NODE_URL="https://nodejs.org/dist/$1/node-$1-linux-x64.tar.gz"
  local NODE_FILE="node-$1-linux-x64.tar.gz"
  echo "Instalar Node: $NODE_FILE"
  # download in root dir
  wget --no-dns-cache -4 -r $NODE_URL -O /root/$NODE_FILE
  [ $? -ne 0 ] && echo "wget error=$?"
  pushd /usr/local >/dev/null
  tar --strip-components 1 --no-same-owner -xzf /root/$NODE_FILE
  # for Ubuntu: https://github.com/nodesource/distributions#debinstall
  popd             >/dev/null
  rm -f /root/$NODE_FILE
  # show versions for debug
  echo "Node version: $(node -v)"
  echo "Npm version: $(npm -v)"
}

#-----------------------------------------------------------------------
# Asks Node.js version
function AskNodeVersion(){
  local FIM N_LIN VER_TMP ERR_MSG
  FIM="N"
  VER_TMP=""
  ERR_MSG=""
  N_LIN=10
  while [ "$FIM" != "Y" ]; do
    MSG="\nWhich version of Node.js do you need:\n$ERR_MSG"
    VER_TMP=$(whiptail --title "$TITLE" --inputbox "$MSG" $N_LIN 74 $VER_TMP 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      return 1
    else
      # Verify if "v" is included in the version name
      [ "${VER_TMP:0:1}" != "v" ] && VER_TMP="v$VER_TMP"
      CheckVerNode $VER_TMP
      if [ $? -eq 0 ]; then
        echo "$VER_TMP"
        return 0
      else
        ERR_MSG="\nERROR: this version was not found, please try again"
        ERR_MSG+="\n (check versions at https://nodejs.org/dist)"
        N_LIN=13
      fi
    fi
  done
}

#-----------------------------------------------------------------------
# Select version of Node.js to install
function NodeSelect(){
  # Last versions of Node.js:
  local EXE OPTION
  local ERR_MSG="\n"
  local LTS_NODE=$(GetVerNodeLts)
  local STB_NODE=$(GetVerNodeStable)
  local CUR_NODE=$(GetVerNodeAtual)
  local VERSION=""

  while [ "$VERSION" == "" ]; do
    EXE="whiptail --title \"$TITLE\""
    # Opções de seleção
    if [ "$CUR_NODE" != "" ]; then
      EXE+=" --nocancel --menu \"$ERR_MSG Select the NODE version you need to install\" 13 75 4 "
      EXE+="\"Current\"  \"  keep current version (recomended): $CUR_NODE\" "
      EXE+="\"LTS\"      \"  LTS version                      : $LTS_NODE\" "
    else
      EXE+=" --nocancel --menu \"Select the NODE version you need to install\" 14 75 3 "
      EXE+="\"LTS\"      \"  LTS version (recomended)         : $LTS_NODE\" "
    fi
    EXE+="\"Stable\"     \"  latest/stable version            : $STB_NODE\" "
    EXE+="\"Custom\"     \"  manually input a version number\" "
    OPTION=$(eval "$EXE 3>&1 1>&2 2>&3")
    [ $? != 0 ] && return 1 # Canceled

    VERSION="";ERR_MSG="\n"
    if [ "$OPTION" == "Current" ]; then
      echo "Keep current version"
      return
    elif [ "$OPTION" == "LTS" ]; then
      VERSION="$LTS_NODE"
    elif [ "$OPTION" == "Stable" ]; then
      VERSION="$STB_NODE"
    elif [ "$OPTION" == "Custom" ]; then
      VERSION=$(AskNodeVersion)
      [ $? != 0 ] && ERR_MSG="(Error...)"
    fi
  done

  # Install ou re-install Node.js
  NodeInstall $VERSION
  # Reinstaled Node.js, needs to reinstall Forever
  npm -g install forever
  # allow execution by "other", not standard!!!
  chmod -R o+rx /usr/local/lib/node_modules
}


#-----------------------------------------------------------------------
# main()

if [ "$CMD" == "--first" ]; then
  #--- First instalation
  NodeSelect

#-----------------------------------------------------------------------
else
  #--- Select version to install
  NodeSelect

fi
#-----------------------------------------------------------------------
