#!/bin/bash
set -x

# Script para instalar e configurar o MongoDB
# Uso: /script/prog-mongo.sh <cmd>
# <cmd>: --first       primeira instalação
#        <sem nada>    Modo interativo, usado pelo nfas


#=======================================================================
# Processa a linha de comando
CMD=$1
# Funções auxiliares
. /script/functions.sh
# Lê dados anteriores se existirem
. /script/info/distro.var
VAR_FILE="/script/info/mongo.var"
CONF_FILE="/etc/mongod.conf"
TITLE="NFAS - Configuração do MongoDB"

#-----------------------------------------------------------------------
# Get Latest stable version
function GetMongoVersion(){
  local URL VER_TMP
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    # Get the correct URL for CentOS 6 and 7
    URL="https://repo.mongodb.org/yum/redhat/$DISTRO_VERSION/mongodb-org/stable/x86_64/RPMS"
    VER_TMP=$(curl -s $URL/ |                                           \
    grep -E "href='mongodb-org-3.*.rpm'" |                             \
    sed -e 's/.*mongodb-org-\([0-9]\.[0-9]\.[0-9]-[0-9]\+\).*/\1/;' |  \
    tail -1)
  else
    echo "Ubuntu..."
  fi
  echo "$VER_TMP"
}

#-----------------------------------------------------------------------
# Instal a version of MongoDB
# usage: MongoInstall <version>
# https://docs.mongodb.com/manual/tutorial/install-mongodb-on-red-hat/
function MongoInstall(){
  local VER EXT FILE1 FILE2 FILE3 FILE4
  VER=$1
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    # Get the correct URL for CentOS 6 and 7
    URL="https://repo.mongodb.org/yum/redhat/$DISTRO_VERSION/mongodb-org/stable/x86_64/RPMS"
    EXT=".el$DISTRO_VERSION.x86_64.rpm"
    # MongoDB consists of 4 files...
    FILE1="mongodb-org-server-$VER$EXT"
    FILE2="mongodb-org-mongos-$VER$EXT"
    FILE3="mongodb-org-shell-$VER$EXT"
    FILE4="mongodb-org-tools-$VER$EXT"
    wget -N $URL/$FILE1 $URL/$FILE2 $URL/$FILE3 $URL/$FILE4
    # Install packages
    rpm -Uvh $FILE1
    rpm -Uvh $FILE2
    rpm -Uvh $FILE3
    rpm -Uvh $FILE4
    [ -e $CONF_FILE.orig ] || cp -afv $CONF_FILE $CONF_FILE.orig   # Preserva original
    # configura SElinux
    echo "Configurando SElinux..."
    semanage port -a -t mongod_port_t -p tcp 27017
    # Cria diretórios e altera direitos
    mkdir -p /var/lib/mongo
    chown mongod:mongod /var/lib/mongo
    mkdir -p /var/log/mongodb
    chown mongod:mongod /var/log/mongodb
    chown mongod:mongod $CONF_FILE
    # Start MongoDB
    chkconfig mongod on
    service mongod start
  else
    echo "Ubuntu..."
  fi
 echo "install"
}

#=======================================================================
# main()

# Read Variables and set defaults
#ReadMongoVars

#-----------------------------------------------------------------------
if [ "$CMD" == "--first" ]; then
  # same as not --first
  MongoInstall
  #MongoMenu
  #MongoConfig

#-----------------------------------------------------------------------
else
  #--- Set options and install
#  GetMongoVersion
  MongoInstall $(GetMongoVersion)
  #MongoMenu
  #MongoConfig

fi
#-----------------------------------------------------------------------
#SaveMongoVars
#=======================================================================


