#!/bin/bash
# set -x

# Script for installing and configuring MongoDB
# Usage: /script/prog-mongo.sh <cmd>
# <cmd>: --first       First install
#        <nothing>     Interative mode, used by menu nfas

# Monit: http://stackoverflow.com/questions/34785499/monit-mongodb-check-does-not-work-with-pid-file-but-works-with-lock-file-why
# Monit: /var/run/mongodb/mongod.pid

#=======================================================================
# Process command line
CMD=$1
# Auxiliary Functions
. /script/functions.sh
# Read previous configurations if they exist
. /script/info/distro.var
VAR_FILE="/script/info/mongo.var"
CONF_FILE="/etc/mongod.conf"
TITLE="NFAS - Installing and Configuring MongoDB"

#-----------------------------------------------------------------------
# Get Latest stable version
function GetMongoVersion(){
  local URL VERSION VERS NUM
  # Get current version from MongoDB download page
  VERSION=$(curl -s https://www.mongodb.com/download-center | sed -n 's/.*Current Stable Release (\([0-9.]\+\).*/\1/p')
  if [ -z "$VERSION" ]; then
    echo "Error..."
  fi
  # separate only 2 first numbers of version
  VERS=$(echo "$VERSION" | sed -n 's/\([0-9]\+\.[0-9]\+\).*/\1/p')
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    # Get the correct URL for CentOS 6 and 7
    URL="https://repo.mongodb.org/yum/redhat/$DISTRO_VERSION/mongodb-org/$VERS/x86_64/RPMS"
    # still missing the extra distribution number in file name, make sure to get the last one
    NUM=$(eval "curl -s $URL/ | sed -n 's/.*\(mongodb-org-$VERSION-[0-9]\+.el6.x86_64.rpm\).*/\1/p' | tail -n1 |  sed -n 's/.*mongodb-org-$VERSION-\([0-9]\+\).el6.x86_64.rpm.*/\1/p'")
    echo "$VERSION-$NUM"
  else
    echo "Ubuntu..."
  fi
}

#-----------------------------------------------------------------------
# Get the current installed MongoDB version
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
  # Create diretories and change permisions
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
    # remove config file from /etc/init.d if it exists
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
  local VERSION VERS EXT FILE1 FILE2 FILE3 FILE4 MONDO_PID
  VERSION=$1
  # separate only 2 first numbers of version
  VERS=$(echo "$VERSION" | sed -n 's/\([0-9]\+\.[0-9]\+\).*/\1/p')
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    # Get the correct URL for CentOS 6 and 7
    URL="https://repo.mongodb.org/yum/redhat/$DISTRO_VERSION/mongodb-org/$VERS/x86_64/RPMS"
    EXT=".el$DISTRO_VERSION.x86_64.rpm"
    # MongoDB consists of 4 files...
    FILE1="mongodb-org-server-$VERSION$EXT"
    FILE2="mongodb-org-mongos-$VERSION$EXT"
    FILE3="mongodb-org-shell-$VERSION$EXT"
    FILE4="mongodb-org-tools-$VERSION$EXT"
    wget -N $URL/$FILE1 $URL/$FILE2 $URL/$FILE3 $URL/$FILE4
    # Install packages
    rpm -Uvh $FILE1
    rpm -Uvh $FILE2
    rpm -Uvh $FILE3
    rpm -Uvh $FILE4
    # remove used files
    rm -f $FILE1 $FILE2 $FILE3 $FILE4
    [ -e $CONF_FILE.orig ] || cp -afv $CONF_FILE $CONF_FILE.orig   # Preserva original
    # configure SElinux
    echo "Configuring SElinux..."
    semanage port -a -t mongod_port_t -p tcp 27017
    # Goneric configurations
    SetupMongoConf
    # Start MongoDB
    chkconfig mongod on
    # Test if mongod is running, then kill it (!dangerous)
    MONDO_PID=$(service mongod status | sed -n 's/.*(pid \([0-9]\+\).*/\1/p')
    if [ -n "$MONDO_PID" ]; then
      echo "Killing mongod..."
      kill $MONDO_PID
      rm -f /var/run/mongodb/mongod.pid
    fi
    # start new version of mongod
    service mongod start
  else
    echo "Ubuntu..."
  fi
 echo "install"
}

#-----------------------------------------------------------------------
# Select MongoDB version
function MongoSelect(){
  # Last version of MongoDB
  local EXE OPTION
  local ERR_MSG="\n"
  local STABLE_MONGO=$(GetMongoVersion)
  local CUR_MONGO=$(GetMongoVerAtual)
  local VERSION=""

  while [ "$VERSION" == "" ]; do
    EXE="whiptail --title \"$TITLE\""
    # Selection options
    if [ "$CUR_MONGO" != "" ]; then
      EXE+=" --nocancel --menu \"$ERR_MSG Select the MongoDB version you need to install\" 13 75 2 "
      EXE+="\"Current\"  \"  keep current version (recomended): $CUR_MONGO\" "
      EXE+="\"Stable\"   \"  last Stable version              : $STABLE_MONGO\" "
    else
      EXE+=" --nocancel --menu \"Select the MongoDB version you need to install\" 14 75 1 "
      EXE+="\"Stable\"   \"  Stable version (recomended)      : $STABLE_MONGO\" "
    fi
    OPTION=$(eval "$EXE 3>&1 1>&2 2>&3")
    [ $? != 0 ] && return 1 # Canceled

    VERSION="";ERR_MSG="\n"
    if [ "$OPTION" == "Current" ]; then
      return
    elif [ "$OPTION" == "Stable" ]; then
      VERSION="$STABLE_MONGO"
    fi
  done

  # Install ou re-install MongoDB
  MongoInstall $VERSION
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
  # Test if mongod is running
  MONDO_PID=$(service mongod status | sed -n 's/.*(pid \([0-9]\+\).*/\1/p')
  if [ -n "$MONDO_PID" ]; then
    MSG="\n\nMongoDB is running, this is dangerous to update..."
    MSG+="\n Plase close MongoDB using it's own tools."
     MSG+="\n\n          Do you really want to continue?"
    whiptail --title "$TITLE" --yesno "$MSG" 12 60
    if [ $? -ne 0 ]; then
      exit
    fi
  fi
  MongoSelect
  # MongoStart

fi
#-----------------------------------------------------------------------
#SaveMongoVars
#=======================================================================


