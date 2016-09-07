#!/bin/bash
set -x

# Script para instalar e configurar o MongoDB
# Uso: /script/prog-mongo.sh <cmd>
# <cmd>: --first       primeira instalação
#        <sem nada>    Modo interativo, usado pelo nfas

# Monit: http://stackoverflow.com/questions/34785499/monit-mongodb-check-does-not-work-with-pid-file-but-works-with-lock-file-why
# Monit: /var/run/mongodb/mongod.pid

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
    VER_TMP=$(curl -s $URL/ |                                          \
    grep -E "href='mongodb-org-3.*.rpm'" |                             \
    sed -e 's/.*mongodb-org-\([0-9]\.[0-9]\.[0-9]-[0-9]\+\).*/\1/;' |  \
    tail -1)
  else
    echo "Ubuntu..."
  fi
  echo "$VER_TMP"
}

#-----------------------------------------------------------------------
# Fornece a versão atual do Node instalada
function GetMongoVerAtual(){
  local VER_TMP=""
  if which mongod >/dev/null; then
    # Gtting version from executable doesn't include the distro version (last digit)
    # mongod --version | grep "db version" | sed -e 's/.*v\([0-9.]*\)/\1/;'
    if [ "$DISTRO_NAME" == "CentOS" ]; then
      VER_TMP=$(rpm -q mongodb-org-server | sed -e 's/.*mongodb-org-server-\([0-9]\.[0-9]\.[0-9]-[0-9]\+\).*/\1/;')
    else
      echo "Ubuntu..."
    fi
  fi
  echo "$VER_TMP"
}

#-----------------------------------------------------------------------
# Setup MongoDB
# Perform various setups for it to work...
function SetupMongoConf(){
  # Cria diretórios e altera direitos
  mkdir -p /var/lib/mongo
  mkdir -p /var/log/mongodb
  chown mongod:mongod /var/lib/mongo
  chown mongod:mongod /var/log/mongodb
  chown mongod:mongod /var/run/mongodb
  chown mongod:mongod /var/run/mongodb/*
  chown mongod:mongod $CONF_FILE
  # bindIp is allways changed to 0.0.0.0
  if grep -E '^[ \t]*bindIp:[ \t]*127' $CONF_FILE; then
    sed -i 's/\([ \t]*bindIp:.*\)/#\1/;' $CONF_FILE
    sed -i '/bindIp:/{p;s/.*/  bindIp: 0.0.0.0/;}' $CONF_FILE
  fi
}

#-----------------------------------------------------------------------
# Set Upstart/Systemd for MongoDB
# WORK IN PROGRESS, this is not working
function MongoStart(){
  if [ "$DISTRO_NAME_VERS" == "CentOS 6" ]; then
    # remove o arquivo do init.d se existir
    ARQ="/etc/init/mongod.conf"
    cat <<- EOF > $ARQ
			#!upstart
			description "MongoDB"

			# Recommended ulimit values for mongod or mongos
			# See http://docs.mongodb.org/manual/reference/ulimit/#recommended-settings
			limit fsize unlimited unlimited
			limit cpu unlimited unlimited
			limit as unlimited unlimited
			limit nofile 64000 64000
			limit rss unlimited unlimited
			limit nproc 64000 64000

			pre-start script
			  MONGOUSER=mongod
			  touch /var/run/mongodb.pid
			  chown \$MONGOUSER /var/run/mongodb.pid
			end script

			start on runlevel [2345]
			stop on runlevel [06]
			# Mongod will fork once, "expect" accomodates for that
			expect 3
			respawn

			script
			  exec >/tmp/mongod.log 2>&1
			  #. /etc/rc.d/init.d/functions
			  ENABLE_MONGODB="yes"
			  # if [ -f /etc/default/mongodb ]; then . /etc/default/mongodb; fi
			  if [ "\$ENABLE_MONGODB" == "yes" ]; then
			    if [ -f /var/lib/mongo/mongod.lock ]; then
			      rm /var/lib/mongo/mongod.lock
			      sudo -u \$MONGOUSER /usr/bin/mongod --config /etc/mongod.conf --repair
			    fi
			    exec sudo -u \$MONGOUSER /usr/bin/mongod --fork --config /etc/mongod.conf
			  fi
			end script
		EOF
    initctl reload-configuration
    start mongod
  fi
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
    # remove used files
    rm -f $FILE1 $FILE2 $FILE3 $FILE4
    [ -e $CONF_FILE.orig ] || cp -afv $CONF_FILE $CONF_FILE.orig   # Preserva original
    # configura SElinux
    echo "Configurando SElinux..."
    semanage port -a -t mongod_port_t -p tcp 27017
    # Goneric configurations
    SetupMongoConf
    # Start MongoDB
    chkconfig mongod on
    service mongod start
  else
    echo "Ubuntu..."
  fi
 echo "install"
}

#-----------------------------------------------------------------------
# Select MongoDB version
function MongoSelect(){
  # Última versão do Node.js:
  local EXE ERR_MSG OPTION
  local STABLE_MONGO=$(GetMongoVersion)
  local CUR_MONGO=$(GetMongoVerAtual)
  local VERSAO=""

  while [ "$VERSAO" == "" ]; do
    EXE="whiptail --title \"$TITLE\""
    # Opções de seleção
    if [ "$CUR_MONGO" != "" ]; then
      EXE+=" --nocancel --menu \"$ERR_MSG Selecione a versão no MongoDB que deseja instalar\" 12 75 2 "
      EXE+="\"Atual\"    \"  manter versão atual (recomendado): $CUR_MONGO\" "
      EXE+="\"Stable\"   \"  última versão Stable             : $STABLE_MONGO\" "
    else
      EXE+=" --nocancel --menu \"Selecione a versão no MongoDB que deseja instalar\" 13 75 1 "
      EXE+="\"Stable\"   \"  versão Stable (recomendado)      : $STABLE_MONGO\" "
    fi
    OPTION=$(eval "$EXE 3>&1 1>&2 2>&3")
    [ $? != 0 ] && return 1 # Cancelado

    VERSAO="";ERR_MSG=""
    if [ "$OPTION" == "Atual" ]; then
      return
    elif [ "$OPTION" == "Stable" ]; then
      VERSAO="$STABLE_MONGO"
    fi
  done

  # Instala ou re-instala o Node.js
  MongoInstall $VERSAO
}


#=======================================================================
# main()

# Read Variables and set defaults
#ReadMongoVars

#-----------------------------------------------------------------------
if [ "$CMD" == "--first" ]; then
  # same as not --first
  MongoSelect

#-----------------------------------------------------------------------
else
  #--- Set options and install
  MongoSelect
  # MongoStart

fi
#-----------------------------------------------------------------------
#SaveMongoVars
#=======================================================================


