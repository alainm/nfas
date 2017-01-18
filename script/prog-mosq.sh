#!/bin/bash
# set -x

# CAUTION: not tested (removed from menu)

# Script para instalar e configurar MQTT - Mosquitto
# Uso: /script/prog-mosq.sh <cmd>
# <cmd>: --first       primeira instalação
#        <sem nada>    Modo interativo, usado pelo nfas

#=======================================================================
# Processa a linha de comando
CMD=$1
# Funções auxiliares
. /script/functions.sh
# Lê dados anteriores se existirem
. /script/info/distro.var
VAR_FILE="/script/info/mosq.var"
CONF_FILE="/etc/mosquitto/mosquitto.conf"
TITLE="NFAS - Configuração do Mosquitto-MQTT"

#-----------------------------------------------------------------------
# Functionto edit Mosquito.conf
# this is different from the general one in function.sh,
# 1) mosquitto has rigid rules on spacing
# 2) default configuration with "#name" without <space> and examples start with "# name"
# usage: MosqEditConf <param> <value>
function MosqEditConf(){
set -x
  local PARAM=$1
  local VAL=$2
  # https://www.gnu.org/software/findutils/manual/html_node/find_html/grep-regular-expression-syntax.html
  if grep -q -E "^$PARAM\b" $CONF_FILE; then
    # Line already exists, inline replacing
    eval "sed -i 's/^\($PARAM\).*/\1 $VAL/;' $CONF_FILE"
  elif grep -q -E "^#$PARAM\b" $CONF_FILE; then
    # Line exists but is commented out, add config after that line
    # http://thobias.org/doc/sosed.html#toc51
    eval "sed -i '/^#$PARAM\b/{p;s/.*/$PARAM $VAL/;}' $CONF_FILE"
  else
    # line does not exist, append to the end of the file
    echo "$PARAM $VAL" >> $CONF_FILE
  fi
set +x
}

#-----------------------------------------------------------------------
# Check if both ports are deactivated and issue a Warning
function CheckBothPorts(){
  local MSG
  if [ -z "$MOSQ_PORT" ] && [ -z "$MOSQ_PORT_S" ]; then
       MSG="\nATENÇÃO: ambas as portas com e sem criptografia estão desativadas,"
    MSG+="\n\n  isto fará com que o Mosquitto-MQTT seja desativado ao retornar!"
      MSG+="\n  Por favor altere uma das duas portas se deseja usar o MQTT"
    whiptail --title "$TITLE" --msgbox "$MSG" 11 75
  fi
}

#-----------------------------------------------------------------------
# Ask for the TCP port to use for MQTT
# "" is valid, means not used
# Usage: AskMqttPort ""|SSL    SSL or blank
# Returns: 0=ok, 1=Abort
function AskMqttPort(){
  local ERR_ST=""
  local PORT_TMP PORT_TMP2 OK
  # Save current port
  [ "$1" != "SSL" ] && PORT_TMP=$MOSQ_PORT || PORT_TMP=$MOSQ_PORT_S
  # loop, only exists with Ok or Abort
  while true; do
       MSG="\nPorta de acesso para o MQTT, "
    [ "$1" != "SSL" ] && MSG+="não criptografado" || MSG+="com criptogrfia SSL/TLS"
    MSG+="\n\nDeixe em branco ou '0' para desabilitar (default="
    [ "$1" != "SSL" ] && MSG+="1883)" || MSG+="8883)"
    MSG+="\n<Enter> para manter o anterior sendo mostrado\n"
    # Acrescenta mensagem de erro
    MSG+="\n$ERR_ST"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    PORT_TMP=$(whiptail --title "$TITLE" --inputbox "$MSG" 14 74 $PORT_TMP 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operação cancelada!"
      return 1
    fi
    # Validate port
    OK="N"
    if [ -z "$PORT_TMP" ] || [ $PORT_TMP -eq 0 ]; then
      PORT_TMP=""
      OK="Y"
    elif [[ $PORT_TMP =~ [0-9]* ]] && [ $PORT_TMP -lt 65536 ]; then
      OK="Y"
    fi
    if [ "$OK" == "Y" ]; then
      # Port accepted
      echo "Porta do servidor de MQTT ok: $PORT_TMP"
      # save result
      [ "$1" != "SSL" ] && MOSQ_PORT=$PORT_TMP || MOSQ_PORT_S=$PORT_TMP
      # Warning about both ports deactivated
      CheckBothPorts
      return 0
    else
      ERR_ST="Porta inválida, por favor tente novamente"
    fi
  done
}

#-----------------------------------------------------------------------
# Ask for Security Level for MQTT
# Returns: 0=ok, 1=canceled
function AskMosqConnType(){
  local DEF_OPT MSG MENU_IT
  if [ -z "$MOSQ_PORT_S" ]; then
     MSG="\nATENÇÃO: A conexão Segura está desabilitadas,"
    MSG+="\n  por favor ative a porta correspondente."
    whiptail --title "$TITLE" --msgbox "$MSG" 9 75
  else
    MSG="\nQual o Nível de Segurança de Criptografia para o MQTT?"
    MSG+="\nselecione conforme a capacidade dos dispositivos"
    [ "$CMD" != "--first" ] && MSG+=" ATUAL=$MOSQ_CRYPT_LEVEL"
    MSG+="\nOBS: crie uma Aplicação corresponde com sub-domínio a ser usado"
    MOSQ_CRYPT_LEVEL=$(whiptail --title "$TITLE" --nocancel --default-item "$MOSQ_CRYPT_LEVEL" \
      --menu "$MSG" --fb 16 76 3                                    \
      "1" "Moderno - Comunicação segura (TLSv1.2, Ephemetal, AES)"  \
      "2" "Intermediário - Compatibilidade (TLSv1, diversos) "      \
      "3" "Antigo - Baixa Segurança (SSLv3...)"                     \
      3>&1 1>&2 2>&3)
  fi
}

#-----------------------------------------------------------------------
# Ask for persistance to use for MQTT
# maximum time is arbitraryly set to 1 year
# Returns: 0=ok, 1=Abort
function AskMqttPersistance(){
  local ERR_ST=""
  local PERS_TMP TMP1 TMP2 OK
  PERS_TMP="$MOSQ_PERS_EXP"
  # loop, only exists with Ok or Abort
  while true; do
     MSG="\nTempo de tersistência do MQTT"
    MSG+="\neste é o tempo para apagar eventos muito antigos..."
    MSG+="\n\nNúmero seguido de uma letra:"
      MSG+=" h=hour, d=day, w=week, m=month e y=year"
    # Acrescenta mensagem de erro
    MSG+="\n\n$ERR_ST"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    PERS_TMP=$(whiptail --title "$TITLE" --inputbox "$MSG" 14 74 $PERS_TMP 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operação cancelada!"
      return 1
    fi
    # Validate response
    OK="N"
    if [[ $PERS_TMP =~ [0-9]*[hdwmy] ]]; then
      TMP1=$(echo "$PERS_TMP" | sed 's/\([0-9]*\).*/\1/')
      TMP2=$(echo "$PERS_TMP" | sed 's/[0-9]*\([hdwmy]\)/\1/')
      # maximum is one year
      [ "$TMP2" == "h" ] && [ $TMP1 -le 8760 ] && [ $TMP1 -gt 0 ] && OK="Y"
      [ "$TMP2" == "d" ] && [ $TMP1 -le 366  ] && [ $TMP1 -gt 0 ] && OK="Y"
      [ "$TMP2" == "w" ] && [ $TMP1 -le 51   ] && [ $TMP1 -gt 0 ] && OK="Y"
      [ "$TMP2" == "m" ] && [ $TMP1 -le 12   ] && [ $TMP1 -gt 0 ] && OK="Y"
      [ "$TMP2" == "y" ] && [ $TMP1 -le 1    ] && [ $TMP1 -gt 0 ] && OK="Y"
    fi
    if [ "$OK" == "Y" ]; then
      # Port accepted
      echo "Persistencia do MQTT ok: $PERS_TMP"
      MOSQ_PERS_EXP="$PERS_TMP"
      return 0
    else
      ERR_ST="Parâmetro inválido, por favor tente novamente"
    fi
  done
}

#-----------------------------------------------------------------------
# Ask for AutoSave time
# Arbitrarily limited between 5 and 3600 seconds
# Returns: 0=ok, 1=Abort
function AskMqttAutoSave(){
  local ERR_ST=""
  local SAVE_TMP TMP OK
  SAVE_TMP="$MOSQ_AUTO_SAVE"
  # loop, only exists with Ok or Abort
  while true; do
     MSG="\nIntervalo de tempo para backup em arquivo"
    MSG+="\nDurante esse tempo, os dados ficam em RAM !!!"
    MSG+="\nNúmero em segundos:"
    # Acrescenta mensagem de erro
    MSG+="\n\n$ERR_ST"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    SAVE_TMP=$(whiptail --title "$TITLE" --inputbox "$MSG" 13 74 $SAVE_TMP 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operação cancelada!"
      return 1
    fi
    # Validate response
    OK="N"
    if [[ $SAVE_TMP =~ [0-9]* ]] && [ $SAVE_TMP -gt 5 ] && [ $SAVE_TMP -lt 3600 ]; then
      # Port accepted
      echo "AutoSave do MQTT ok: $SAVE_TMP"
      MOSQ_AUTO_SAVE="$SAVE_TMP"
      return 0
    else
      ERR_ST="Parâmetro inválido, por favor tente novamente"
    fi
  done
}

#-----------------------------------------------------------------------
# Install Mosquitto if any port is enabled
# Get current version: mosquitto -h | grep version | sed 's/.*version \([0-9\.]*\).*/\1/;'
function MosqInstall(){
set -x
  local PKT_URL PKT_FILE
  if [ -z "$MOSQ_PORT" ] && [ -z "$MOSQ_PORT_S" ]; then
    # mosquito is disabled
    return 1
  else
    if which mosquitto >/dev/null; then
      # Not installed
      if [ "$DISTRO_NAME" == "CentOS" ]; then
        if [ "$DISTRO_VERSION" == "6" ]; then
          PKT_URL="http://download.opensuse.org/repositories/home:/oojah:/mqtt/CentOS_CentOS-6/home:oojah:mqtt.repo"
        elif [ "$DISTRO_VERSION" == "7" ]; then
          PKT_URL="http://download.opensuse.org/repositories/home:/oojah:/mqtt/CentOS_CentOS-7/home:oojah:mqtt.repo"
        fi
        PKT_FILE="/etc/yum.repos.d/mosquito.repo"
        wget --no-dns-cache -4 -r $PKT_URL -O $PKT_FILE
        yum -y install mosquitto mosquitto-clients libmosquitto1
      else
        echo "Ubuntu..."
      fi
      # Copy the example file for mosquitto.conf
      if [ ! -e $CONF_FILE ]; then
        cp $CONF_FILE.example $CONF_FILE
      fi
    fi
  fi
set +x
}

#-----------------------------------------------------------------------
# Configure Mosquitto, original file is edited
function MosqConfig(){

  MosqEditConf allow_anonymous false
}

#-----------------------------------------------------------------------
# Setup Menu
function MosqMenu(){
  local CAN_MSG MSG MN_PORT MN_PORTS MN_LEVEL MN_PERS MN_SAVE MENU_IT
  # Cancel button message
  [ "$CMD" == "--first" ] && CAN_MSG="Terminar" || CAN_MSG="Retornar"
  # Loop do Menu principal interativo
  while true; do
     MN_PORT="Porta de acesso (sem criptografia),   ATUAL="
    [ -n "$MOSQ_PORT" ] &&  MN_PORT+="$MOSQ_PORT" || MN_PORT+="desativada"
    MN_PORTS="Porta de acesso criptografada,        ATUAL="
    [ -n "$MOSQ_PORT_S" ] &&  MN_PORTS+="$MOSQ_PORT_S" || MN_PORTS+="desativada"
    MN_LEVEL="Nível de segurança SSL,               ATUAL="
    if [ "$MOSQ_CRYPT_LEVEL" == "1" ]; then
      #         "2 (intermediário, com12)" <= Max Length for width  =78
      MN_LEVEL+="1 (mais seguro, moderno)"
    elif [ "$MOSQ_CRYPT_LEVEL" == "3" ]; then
      MN_LEVEL+="3 (antigo, SSLv3)"
    else
      MN_LEVEL+="2 (intermediário)"
    fi
     MN_PERS="Tempo de Persistência (apaga velhos), ATUAL=$MOSQ_PERS_EXP"
     MN_SAVE="Tempo de auto-save para disco,        ATUAL=$MOSQ_AUTO_SAVE""s"
    MENU_IT=$(whiptail --title "$TITLE" --fb --cancel-button "$CAN_MSG" \
        --menu "\nOpções de configuração:" 18 78 7   \
        "1" "$MN_PORT"                            \
        "2" "$MN_PORTS"                           \
        "3" "$MN_LEVEL"                           \
        "4" "$MN_PERS"                            \
        "5" "$MN_SAVE"                            \
        "6" "Cria novo Usuário/Senha"             \
        "7" "Apaga Usuário existente"             \
        3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
        echo "Terminou"
        return 0
    fi
    # Funções que ficam em Procedures
    [ "$MENU_IT" == "1" ] && AskMqttPort
    [ "$MENU_IT" == "2" ] && AskMqttPort "SSL"
    [ "$MENU_IT" == "3" ] && AskMosqConnType
    [ "$MENU_IT" == "4" ] && AskMqttPersistance
    [ "$MENU_IT" == "5" ] && AskMqttAutoSave
    [ "$MENU_IT" == "6" ] && echo "NewUser"
    [ "$MENU_IT" == "7" ] && echo "DelUser"
  done
}

#-----------------------------------------------------------------------
# Read Mosquitto saved Vars
# if not set, provide reasonable defaults
function ReadMosqittoVars(){
  # Erase previous values ans set compatibility
  MOSQ_PORT="1883"
  MOSQ_PORT_S="8883"
  MOSQ_CRYPT_LEVEL="3"
  MOSQ_PERS_EXP="2m"
  MOSQ_AUTO_SAVE="300"
  # Read already existing file
  [ -e $VAR_FILE ] && . $VAR_FILE
}

#-----------------------------------------------------------------------
# Save Setup variables
# These will be used by other modules end for future iteraction
function SaveMosqittoVars(){
  echo "MOSQ_PORT=\"$MOSQ_PORT\""                  2>/dev/null >  $VAR_FILE
  echo "MOSQ_PORT_S=\"$MOSQ_PORT_S\""              2>/dev/null >> $VAR_FILE
  echo "MOSQ_CRYPT_LEVEL=\"$MOSQ_CRYPT_LEVEL\""    2>/dev/null >> $VAR_FILE
  echo "MOSQ_PERS_EXP=\"$MOSQ_PERS_EXP\""          2>/dev/null >> $VAR_FILE
  echo "MOSQ_AUTO_SAVE=\"$MOSQ_AUTO_SAVE\""        2>/dev/null >> $VAR_FILE
}

#=======================================================================
# main()

# Read Variables and set defaults
ReadMosqittoVars

#-----------------------------------------------------------------------
if [ "$CMD" == "--first" ]; then
  MosqMenu

#-----------------------------------------------------------------------
else
  #--- Set options and install
  # MosqMenu
  # MosqInstall
  cp -f $CONF_FILE.example $CONF_FILE
  MosqConfig

fi
#-----------------------------------------------------------------------
SaveMosqittoVars
#=======================================================================
