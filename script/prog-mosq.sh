#!/bin/bash
set -x

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
TITLE="NFAS - Configuração do Mosquitto-MQTT"

#-----------------------------------------------------------------------
# Check if both ports are deactivated and issue a Warning
function CheckBothPorts(){
  local MSG
  if [ -z "$MOSQ_PORT" ] && [ -z "$MOSQ_PORT_S" ]; then
  # mensagem de confirmação
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
    if [ -z "$PORT_TMP" ] || [ "$PORT_TMP" == "" ] || [ $PORT_TMP -eq 0 ]; then
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
      MN_LEVEL+="3 (antigo, SSL1)"
    else
      MN_LEVEL+="2 (intermediário)"
    fi
     MN_PERS="Tempo de Persistência (apaga velhos), ATUAL=$MOSQ_PERS_EXP"
     MN_SAVE="Tempo de auto-save para disco,        ATUAL=$MOSQ_AUTO_SAVE"
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
    [ "$MENU_IT" == "3" ] && echo "Level"
    [ "$MENU_IT" == "4" ] && echo "Persist"
    [ "$MENU_IT" == "5" ] && echo "autoSave"
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
  MosqMenu

fi
#-----------------------------------------------------------------------
SaveMosqittoVars
#=======================================================================
