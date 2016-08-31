#!/bin/bash
# set -x

# Script para instalar e configurar o RabitMQ
# Uso: /script/prog-rabit.sh <cmd>
# <cmd>: --first       primeira instalação
#        <sem nada>    Modo interativo, usado pelo nfas

#=======================================================================
# Processa a linha de comando
CMD=$1
# Funções auxiliares
. /script/functions.sh
# Lê dados anteriores se existirem
. /script/info/distro.var
VAR_FILE="/script/info/rabit.var"
# CONF_FILE="/etc/mosquitto/mosquitto.conf"
TITLE="NFAS - Configuração do RabitMQ"

#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# Ask for the TCP port to use for RabitMQ
# Returns: 0=ok, 1=Abort
function AskRabitPort(){
  local ERR_ST=""
  local PORT_TMP
  # Save current port
  PORT_TMP=$RABT_PORT
  # loop, only exists with Ok or Abort
  while true; do
    MSG="\nPorta de acesso para o RabitMQ, somente uso interno"
    MSG+="\n\n<Enter> para manter o anterior sendo mostrado\n"
    # Acrescenta mensagem de erro
    MSG+="\n$ERR_ST"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    PORT_TMP=$(whiptail --title "$TITLE" --inputbox "$MSG" 14 74 $PORT_TMP 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operação cancelada!"
      return 1
    fi
    # Validate port
    if [[ $PORT_TMP =~ [0-9]* ]] && [ $PORT_TMP -gt 0 ] && [ $PORT_TMP -lt 65536 ]; then
      # Port accepted
      echo "Porta do servidor de RabitMQ ok: $PORT_TMP"
      # save result
      RABT_PORT=$PORT_TMP
      return 0
    else
      ERR_ST="Porta inválida, por favor tente novamente"
    fi
  done
}

#-----------------------------------------------------------------------
# Setup Menu
function RabitMenu(){
  local MSG MENU_IT MN_PORT
  # Cancel button message
  [ "$CMD" == "--first" ] && CAN_MSG="Terminar" || CAN_MSG="Retornar"
  # Loop do Menu principal interativo
  while true; do
     MN_PORT="Porta de acesso,               ATUAL=$RABT_PORT"
    MENU_IT=$(whiptail --title "$TITLE" --fb --cancel-button "$CAN_MSG" \
        --menu "\nOpções de configuração:" 18 78 1  \
        "1" "$MN_PORT"                              \
        3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
        echo "Terminou"
        return 0
    fi
    # Funções que ficam em Procedures
    [ "$MENU_IT" == "1" ] && AskRabitPort
  done
}

#-----------------------------------------------------------------------
# Read Mosquitto saved Vars
# if not set, provide reasonable defaults
function ReadRabitVars(){
  # Erase previous values ans set compatibility
  RABT_PORT="5672"
  # Read already existing file
  [ -e $VAR_FILE ] && . $VAR_FILE
}

#-----------------------------------------------------------------------
# Save Setup variables
# These will be used by other modules end for future iteraction
function SaveRabitVars(){
  echo "RABT_PORT=\"$RABT_PORT\""                  2>/dev/null >  $VAR_FILE
}

#=======================================================================
# main()

# Read Variables and set defaults
ReadRabitVars

#-----------------------------------------------------------------------
if [ "$CMD" == "--first" ]; then
  RabitMenu

#-----------------------------------------------------------------------
else
  #--- Set options and install
  RabitMenu
  # MosqInstall
  #cp -f $CONF_FILE.example $CONF_FILE
  #MosqConfig

fi
#-----------------------------------------------------------------------
SaveRabitVars
#=======================================================================

