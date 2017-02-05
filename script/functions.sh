#
# File with all basic functions, this is included by several scripts
#
# set -x

# Use: with the command ". " (dot espaço)
# . /script/functions.sh

# TODO: move some functions (loke ask PublicKey) to a separate file

#-----------------------------------------------------------------------
# http://ask.xmodulo.com/compare-two-version-numbers.html
function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

#-----------------------------------------------------------------------
# Function to extract an IP from ifconfig output, has to work everywhere (pt, en, arm)
# usage: IP=$(ifconfig eth0 | GetIpFromIfconfig)
function GetIpFromIfconfig(){
  # sed -n '/.*inet /s/ *\(inet *\)\([A-Za-z\.: ]*\)\([\.0-9]*\).*/\3/p'
  sed -n '/.*inet /s/ *inet \+[A-Za-z\.: ]*\([\.0-9]*\).*/\1/p'
}

#-----------------------------------------------------------------------
# Function to extract IPv4 of a device
# usage: IP=$(GetIPv4 eth0)
function GetIPv4(){
  local DEV=$1
  [ -z "$DEV" ] && echo "InvalidDev"
  LANG=C ifconfig $DEV | GetIpFromIfconfig
}

#-----------------------------------------------------------------------
# Function to extract NetMask4 ao a device
# usage: IP=$(GetIPv4 eth0)
function GetMask4(){
  local DEV=$1
  [ -z "$DEV" ] && echo "DevInvalido"
  LANG=C ifconfig $DEV | grep "inet addr:" | sed -n 's/.*Mask:\([0-9.]*\).*/\1/p'
}
#-----------------------------------------------------------------------
# Function to extract the GATEWAY
# usage GW=$(GetGateway)
function GetGateway(){
  route -n | grep -E "^0.0.0.0.*UG.*" | tr -s ' ' | cut -d' ' -f2 | tail -1
}
#-----------------------------------------------------------------------
# Function to extract the DNS server
# usage GW=$(GetDnsServer)
function GetDnsServer(){
  # cat /etc/resolv.conf | grep -m 1 -E "^nameserver" | sed -n 's/.* \([0-9.]*\)/\1/p'
  cat /etc/resolv.conf | grep -E "^nameserver" | sed -n 's/.* \([0-9.]*\)/\1/p' | tr  '\n' ' '
}

#-----------------------------------------------------------------------
# Function to detect if ping returns "Network is unreachable"
# usage: NET_OK=$(NetwokState)
# retorns: "OK"   if network is ok
#          "DOWN" if network is disconnected or DOWN
#          "UN"   if network is UP but is "UNREACHEABLE": problem with route
function GetNetwokState(){
  local ST=$(ip a | sed -n "/eth0:/s/.* state \([A-Z]*\).*/\1/p")
  if [ "$ST" == "DOWN" ]; then
    echo "DOWN"
  else
    local T=$(LANG=C ping -c1 -W1 8.8.8.8 2>&1 | grep 'Network is unreachable')
    if [ -z "$T" ]; then
      echo "OK"
    else
      echo "UN"
    fi
  fi
}

#-----------------------------------------------------------------------
# Function to determine if login used password oo publickey
function GetLoginType(){
  # Determine return port of current connection
  local LOG_PORT=$(echo $SSH_CONNECTION | cut -d' ' -f2)
  if [ -z "$LOG_PORT" ]; then
    echo "NotSsh"
  else
    # Get Log message for current connection
    local LOG_MSG=$(grep "Accepted [password|publickey]" /var/log/secure | grep -m1 "port $LOG_PORT"| tail -1)
    # retorns keyword
    echo  "$LOG_MSG" | sed -n 's/.*\(password\|publickey\).*/\1/p'
  fi
}

#-----------------------------------------------------------------------
# Retuns a list of existing Applications (Linux users)
function GetAppList(){
  local U
  local APP_LIST=""
  # Create lis of Applications as Linux users
  for U in $(ls -d /home/*); do
    USR=$(echo "$U" | sed -n 's@/home/\(.*\)*@\1@p')
    [ -n "$APP_LIST" ] && APP_LIST+=" "
    APP_LIST+=$USR
  done
  echo "$APP_LIST"
}

#-----------------------------------------------------------------------
# Function to edit a Config file, param separated by "="
# Param format is: "param=value", separator is "="
# Bash style, without <space> before/after "="
# usage: EditConfEqualSafe <file> <param> <value>
# used by: clock, function, network, RabitMQ
function EditConfEqualSafe(){
  local FILE=$1
  local PARAM=$2
  local VAL=$3
  if grep -E "^[[:blank:]]*$PARAM[[:blank:]]*=" $FILE; then
    # Line already exists, need to remove before creating a new one
    sed -i /^[[:blank:]]*$PARAM[[:blank:]]*=/d $FILE
  fi
  # Line with param does not exist (or was deleted), append that line
  echo -e "\n$PARAM=$VAL" 2>/dev/null >> $FILE
}

#-----------------------------------------------------------------------
# Function to edit a Config file, param separated by "="
# Param format is: "param=\"value\"", separator is "="
# String version: value is between quotes
# Bash style, without <space> before/after "="
# usage: EditConfEqualStr <file> <param> <value>
# usado por: clock, function
function EditConfEqualStr(){
  local FILE=$1
  local PARAM=$2
  local VAL=$3
  if grep -E "^[[:blank:]]*$PARAM[[:blank:]]*=" $FILE; then
    # Line already exists, need to remove before creating a new one
    sed -i /^[[:blank:]]*$PARAM[[:blank:]]*=/d $FILE
  fi
  # Line with param does not exist (or was deleted), append that line
  echo -e "\n$PARAM=\"$VAL\"" 2>/dev/null >> $FILE
}

#-----------------------------------------------------------------------
# Function to READ a Config file, param separated by "="
# usage: GetConfEqual <file> <param>
# Remove quotes, if they exist. TODO: only if at begin/end
function GetConfEqual(){
  local FILE=$1
  local PARAM=$2
  local TMP=$(eval "sed -n 's|^[[:blank:]]*$PARAM=\(.*\)|\1|p' $FILE | tr -d \"\\\"\"")
  echo "$TMP"
}

#-----------------------------------------------------------------------
# Function to edit a Config file, param separated by ":"
# Format of params: "param:  value", the separator is ":"
# usage: EditConfColon <file> <param> <value>
# Uses method of Delete and Create, this is safer!
#   (some caracters could be interpreted by SED)
# used by: postfix (/etc/aliases)
function EditConfColon(){
  local FILE=$1
  local PARAM=$2
  local VAL=$3
  if grep -E "^[[:blank:]]*$PARAM[[:blank:]]*:" $FILE; then
    # Line already exists, need to remove before creating a new one
    sed -i /^[[:blank:]]*$PARAM[[:blank:]]*:/d $FILE
  fi
  # Line with param does not exist (or was deleted), append that line
  echo -e "\n$PARAM:   $VAL" >> $FILE
}

#-----------------------------------------------------------------------
# Function to READ a Config file, param separated by " "
# Format of params: "param  value" the separator is " "
# usage: GetConfSpace <file> <param>
# used by sshd.conf
function GetConfSpace(){
  local FILE=$1
  local PARAM=$2
  # Read vaiable from file
  local TMP=$(eval "sed -n 's/^[[:blank:]]*"$PARAM"[[:blank:]]\+\(.*\)[[:blank:]]*$/\1/p'" $FILE)
  if [ -z "$TMP" ]; then
    # Try to read from comments, usualy this is the default
    TMP=$(eval "sed -n 's/^[[:blank:]]*#\?[[:blank:]]*"$PARAM"[[:blank:]]\+\(.*\)[[:blank:]]*$/\1/p'" $FILE)
  fi
  echo $TMP
}

#-----------------------------------------------------------------------
# Function to edit a Config file, param separated by " "
# Format of params: "param  value" the separator is " "
# usage: EditConfSpace <file> <param> <value>
# Uses replace method, BEWARE of characters that could be interpreted by SED
# used by sshd.conf
function EditConfSpace(){
  local FILE=$1
  local PARAM=$2
  local VAL=$3
  if grep -E "^[[:blank:]]*$PARAM[[:blank:]]+" $FILE; then
    # Line already exists, edit inplace
    # Caution, with grep use "+" with sed use "\+"
    eval "sed -i 's/^\([[:blank:]]*$PARAM[[:blank:]]\+\).*/\1$VAL/;' $FILE"
  elif grep -E "^[[:blank:]]*#*[[:blank:]]*$PARAM[[:blank:]]+" $FILE; then
    # Line already exists in comment, remove comment
    eval "sed -i 's/^[[:blank:]]*#\?\([[:blank:]]*$PARAM[[:blank:]]\+\).*/\1$VAL/;' $FILE"
  else
    # Line with param does not exist, append new at the end
    echo -e "\n$PARAM   $VAL" >> $FILE
  fi
}
#-----------------------------------------------------------------------
# Function to edit a Bash file, param separated by " "
# Format of params: "param  value" the separator is " "
# usage: EditConfSpace <file> <param> <value>
# Uses replace method, BEWARE of characters that could be interpreted by SED
# used by sshd.conf
function EditConfBashExport(){
  local FILE=$1
  local PARAM=$2
  local VAL=$3
  if grep -E "^[[:blank:]]*export[[:blank:]]*$PARAM[[:blank:]]*=" $FILE; then
    # Line already exists, edit inplace
    # Caution, with grep use "+" with sed use "\+"
    eval "sed -i 's#^[[:blank:]]*\(export[[:blank:]]*$PARAM[[:blank:]]*=\).*#\1$VAL#;' $FILE"
  else
    # Line with param does not exist, append new at the end
    echo -e "\nexport $PARAM=$VAL" >> $FILE
  fi
}


#-----------------------------------------------------------------------
# Function to edit a Config file with sections, param separated by "="
# Format of params:
#     [section]
#     param = value
# usage: EditConfEqualSect <file> <section> <param> <value>
# Uses replace method, BEWARE of characters that could be interpreted by SED
# used by: fail2ban
function EditConfEqualSect(){
  local FILE=$1
  local SECTION=$2
  local PARAM=$3
  local VAL=$4
  local TMP=$(eval "sed -n '/[$SECTION]/,/\[.*/ { /^[[:blank:]]*$PARAM[[:blank:]]*=/p }' $FILE")
  if [ -n "$TMP" ]; then
    # Line already exists, edit inplace
    eval "sed -i '/[$SECTION]/,/\[.*/ { s/^\([[:blank:]]*$PARAM[[:blank:]]*=[[:blank:]]*\).*/\1$VAL/ }' $FILE"
   else
     TMP=$(eval "sed -n '/[$SECTION]/,/\[.*/ { /^[[:blank:]]*#[[:blank:]]*$PARAM[[:blank:]]*=/p }' $FILE")
     if [ -n "$TMP" ]; then
       # Line already exists in comment, remove comment and edit in place
       eval "sed -i '/[$SECTION]/,/\[.*/ { s/^[[:blank:]]*#\?[[:blank:]]*\($PARAM[[:blank:]]*=[[:blank:]]*\).*/\1$VAL/ }' $FILE"
     else
       # File is separated in []sections], cannot append a line
       false
     fi
  fi
}

#-----------------------------------------------------------------------
# Modify system's localtime
# usage: SetLocaltime <zone>
function SetLocaltime(){
  local NEW_TZ=$1
  if [ -e "/usr/share/zoneinfo/$NEW_TZ" ]; then
    ln -sf /usr/share/zoneinfo/$NEW_TZ /etc/localtime
    # Change config file, changes for different distros
    if [ "$DISTRO_NAME" == "CentOS" ]; then
      EditConfEqualStr /etc/sysconfig/clock ZONE "$NEW_TZ"
    else
      echo "$NEW_TZ" > /etc/timezone
    fi
    return 0
  else
    return 1
  fi
}

#-----------------------------------------------------------------------
# Get system timezone String
function GetLocaltime(){
    if [ "$DISTRO_NAME" == "CentOS" ]; then
      echo "$(GetConfEqual /etc/sysconfig/clock ZONE)"
    else
      cat /etc/timezone
    fi

}

#-----------------------------------------------------------------------
# Import a PublicKey
# Usage: AskNewKey <user> <diretory>
function AskNewKey(){
  local TMP
  local MSG
  local OLD_N
  local USR=$1
  local DIR=$2
  # Determina grupo do USR
  local GRP=$(id -G -n  $USR | cut -d ' ' -f 1)
  # loop só sai com return
  while true; do
       MSG="\nSupply a PublicKey for access as user \"$USR\""
      MSG+="\n (leave it blank if you don't intend to use one)"
    MSG+="\n\nUse these Linux comands to generate a new Key Pair with identification"
      MSG+="\n (copy and execute one line at a time with <Ctrl+Shift+C> <Ctrl+Shift+V>)"
    MSG+="\n\n   FILE=\"\$USER@\$(hostname).key.pub\""
      MSG+="\n   ssh-keygen -t rsa -b 4096 -f ~/.ssh/$USR@$(hostname).key -C \$FILE"
      MSG+="\n   cat ~/.ssh/$USR@$(hostname).key.pub"
    MSG+="\n\nCopy the result in the space below (from \"ssh-rsa\" up to \".pub\"):"
    MSG+="\n"
    # using whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    TMP=$(whiptail --title "PublicKey for user $USR" --inputbox "$MSG" 21 78 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ] || [ -z "$TMP" ]; then
      echo "Operation aborted!"
      return 1
    else
      # Create diretory if non existant
      mkdir -p $DIR/.ssh/; chown $USR:$GRP $DIR/.ssh/; chmod 700 $DIR/.ssh/
      if [ "$DISTRO_NAME" == "CentOS" ]; then
        ## >>CentOS<<: http://wiki.centos.org/HowTos/Network/SecuringSSH
        # Ensure the correct SELinux contexts are set:
        restorecon -Rv $DIR/.ssh
      fi
      # Test if a PublicKey with this identification already exists
      OLD_N=$(eval "sed -n '/"$(echo -n $TMP | cut -d' ' -f3)"/p' $DIR/.ssh/authorized_keys | wc -l")
      if [ $OLD_N -ne 0 ]; then
        MSG="A PublicKey with this identification already exists"
        MSG+="\n\n Do you really want to REPLACE IT?"
        if ( ! whiptail --title "PublicKey for user $USR" --yesno "$MSG" 10 78) then
          continue
        fi
      fi
      # Elimate entries with the same identification
      eval "sed -i '/"$(echo -n $TMP | cut -d' ' -f3)"/d' $DIR/.ssh/authorized_keys"
      # Add a new PublicKey
      echo -e "\n$TMP" >> $DIR/.ssh/authorized_keys
      # It is mandatory to have restrictive permisions
      chown $USR:$GRP $DIR/.ssh/authorized_keys;
      chmod 600 $DIR/.ssh/authorized_keys
      # Remove blank lines
      sed -i '/^$/d' $DIR/.ssh/authorized_keys
      # Send Email with access instructions
      /script/ssh.sh --email $USR
      # Confirmation message
      if [ $OLD_N -eq 0 ]; then
        MSG="\nYour PublicKey was added for safe access."
      else
        MSG="\nYour PublicKey was replaced for safe access."
      fi
      MSG+="\nYour command to access this server using SSH is:"
      MSG+="\n\n   ssh -i ~/.ssh/$USR@$(hostname).key $USR@$(ifconfig eth0 | GetIpFromIfconfig)"
      MSG+="\n\n==>> An email was sent with these instuctions <<=="
      MSG+="\nPlease test it NOW..."
      MSG+="\n\nOK? YES to continue, NO to repeat the operation"
      if (whiptail --title "PublicKey for user $USR" --yesno "$MSG" 17 78) then
        echo "PublicKey successfuly added"
        return 0
      fi
    fi
  done
}

#-----------------------------------------------------------------------
# Remove existing PublicKeys
# Usage: DeleteKeys <user> <diretory>
function DeleteKeys(){
  local I LIN MSG EXE KEYS
  local AMSG=
  local USR=$1
  local DIR=$2
  local TITLE="NFAS - Removing PublicKeys for user: $USR"
    # Remove blank lines
  if [ -e $DIR/.ssh/authorized_keys ]; then
    sed -i '/^$/d' $DIR/.ssh/authorized_keys
    # List all existing keys and place them in an array
    I=0
    while read LIN ; do
      AMSG[$I]=$(echo $LIN | cut -d' ' -f3)
      let I=I+1
    done < $DIR/.ssh/authorized_keys
    N_LIN=${#AMSG[*]} # Number of lines
  else
    N_LIN=0
  fi
    if [ "$N_LIN" == "0" ]; then
      # using whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
      whiptail --title "$TITLE" --msgbox "No PublicKey was found for user $USR.\n\n                   Press OK to continue..." 9 70
      return 0
    fi
    EXE="whiptail --title \"$TITLE\""
    EXE+=" --checklist \"\nSelect the PublicKeys that you want to remove\" 22 75 $N_LIN"
    for ((I=0; I<N_LIN; I++)); do
      # Create mensages for selecting the Keys to be removed
      EXE+=" \"${AMSG[$I]}\" \"\" OFF"
    done
    KEYS=$(eval "$EXE 3>&1 1>&2 2>&3")
    [ $? != 0 ] && return 0 # Aborted
    # Remove selected keys
    for K in $(echo $KEYS | tr -d '\"'); do
      echo "Removing Key: $K"
      eval "sed -i '/"$K"/d' $DIR/.ssh/authorized_keys"
    done
}

#-----------------------------------------------------------------------
