#!/bin/bash
# set -x

# Script para instalar e configurar programas mais comuns
# Uso: /script/ssh.sh <cmd>
# <cmd>: --first       primeira instalação
#        --hostname    Alterado hostname, usado por git
#        --email       Alterado Email, usado por git
#        <sem nada>    Modo interativo, usado pelo nfas

#=======================================================================
# Processa a linha de comando
CMD=$1
# Funções auxiliares
. /script/functions.sh
# Lê dados anteriores se existirem
. /script/info/distro.var
. /script/info/hostname.var
. /script/info/email.var
VAR_FILE="/script/info/progs.var"
[ -e $VAR_FILE ] && . $VAR_FILE


#-----------------------------------------------------------------------
# Instala programas pré configurados
function ProgsInstall(){
  local MSG1=""
  if [ "$CMD" == "--first" ]; then
    MSG="Instalar"
    NODE_MSG=" (Obrigatório)"
    NODE_OPT=YES
  else
    MSG="Instalar/Alterar"
    NODE_MSG=""
    NODE_OPT=NO
  fi
  local OPTIONS=$(whiptail --title "$TITLE"                         \
    --checklist "\nSelecione os programas que deseja $MSG:" 22 75 4 \
    'Node'     "  Node.js $NODE_MSG" $NODE_OPT            \
    'MongoDB'  "  Banco de dados"    NO                   \
    'Rabbit'   "  RabitMQ - Servidor de filas AMQP"  NO   \
    'Mosquito' "  MQTT - Storage para IoT"  NO            \
    3>&1 1>&2 2>&3)
  if [ $? == 0 ]; then
    # Tira as Aspas e Força a opção Node
    OPTIONS=$(echo $OPTIONS | tr -d '\"')
    if [ "$CMD" == "--first" ]; then
      echo $OPTIONS | grep "Node"; [ $? -ne 0 ] && OPTIONS="Node $OPTIONS"
    fi
    #--- Instala programas selecionados
    echo "Opt list=[$OPTIONS]"
    for OPT in $OPTIONS; do
      echo "Instalação: $OPT"
      case $OPT in
        "Node")
          /script/prog-node.sh $CMD
        ;;
        "MongoDB")
          echo "Instala MongoDB..."
        ;;
        "Rabbit")
          /script/prog-rabit.sh $CMD
        ;;
        "MQTT")
          echo "Instala MQTT..."
        ;;
      esac
    done # for OPT
  fi
}
#-----------------------------------------------------------------------
# main()

TITLE="NFAS - Configuração e Instalaçao de Utilitários"
if [ "$CMD" == "--first" ]; then
  #--- Seleciona os programas a instalar
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
  #--- Seleciona os programas a instalar
  ProgsInstall
fi
