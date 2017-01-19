#!/bin/bash
# set -x

# === USER MENU ===

# Called by the command: nfas
# Allows access to configurations available after install
# A link was created in /usr/bin/nfas for this script script

# Read prvious config
. /script/info/email.var
# Global variables
APP_NAME=""
TITLE="NFAS - Node.js Full Application Server - Menu"

# Only root can run this script
if [ "$(id -u)" != "0" ]; then
  echo "Only root can run this command"
  exit 255
fi

#-----------------------------------------------------------------------
# Application Configuration Menu
function ConfigAppMenu() {
  # Read read return variables from selection/creation
  . /script/info/tmp.var
  whiptail --title "$TITLE" --msgbox "ConfigAppMenu, App=$APP_NAME" 8 60
}

#-----------------------------------------------------------------------
# Applications Menu loop
function AppMenu(){
  local CUR_SSL
  while true; do
    # Get global security level every time, it may change
    . /script/info/haproxy.var
    [ "$HAP_CRYPT_LEVEL" == "1" ] && CUR_SSL="MODERN"
    [ "$HAP_CRYPT_LEVEL" == "2" ] && CUR_SSL="INTERMEDIATE"
    [ "$HAP_CRYPT_LEVEL" == "3" ] && CUR_SSL="ANTIQUE"
    # Show menu
    MENU_IT=$(whiptail --title "$TITLE" --cancel-button "Back"     \
        --menu "Select a reconfiguration command:" --fb 20 75 4    \
        "1" "Config an existing Application"                       \
        "2" "Create a NEW Application (Linux user)"                \
        "3" "List existing Applications and domains/URIs"               \
        "4" "Global Security Level for HTTP/SSL, current=$CUR_SSL" \
        3>&1 1>&2 2>&3)
    [ $? != 0 ] && return

    # Next menu or operation
    [ "$MENU_IT" == "3" ] && /script/userapp.sh --list
    [ "$MENU_IT" == "4" ] && /script/haproxy.sh --ssl

    # Create or select an Application
    if [ "$MENU_IT" == "1" ]; then
      /script/userapp.sh --chgapp      # Select Application from /home and users
      ConfigAppMenu                    # Next Menu
    fi
    if [ "$MENU_IT" == "2" ]; then
      /script/userapp.sh --newapp      # Create and configure defaults
      [ $? == 0 ] && ConfigAppMenu     # if not aborted, Next Menu
    fi
  done # loop menu principal
}

#-----------------------------------------------------------------------
# Main iteractive loop
# main()
while true; do
  MENU_IT=$(whiptail --title "$TITLE" --cancel-button "End"     \
      --menu "\nSelect a reconfiguration command:" --fb 20 75 5 \
      "1" "List existing Applications and domains/URIs"              \
      "2" "Manage Applications, create/config and Access"       \
      "3" "Machine config: Hostname, notificaçions, RTC..."     \
      "4" "Machine Security: SSH, root..."                      \
      "5" "Install pre-configured Programs"                     \
      3>&1 1>&2 2>&3)
  if [ $? != 0 ]; then
      echo "Menu closed."
      # Before exiting, must verify if HAproxy canfig has changed
      . /script/info/haproxy.var
      if [ "$HAP_NEW_CONF" == "Y" ]; then
        /script/haproxy.sh --reconfig
      fi
      exit 0
  fi

  # Próximo menu ou funções para cada operação
  [ "$MENU_IT" == "1" ] && /script/userapp.sh --list
  [ "$MENU_IT" == "2" ] && AppMenu
  [ "$MENU_IT" == "3" ] && echo "3: máquina"
  [ "$MENU_IT" == "4" ] && /script/ssh.sh
  [ "$MENU_IT" == "5" ] && /script/progs.sh
done # loop menu principal

#-----------------------------------------------------------------------
# Loop do Menu principal interativo
function OldMenu(){
  while true; do
    MENU_IT=$(whiptail --title "NFAS - Node.js Full Application Server" \
        --cancel-button "Terminar"                                      \
        --menu "Selecione um comando de reconfiguração:" --fb 20 70 9   \
        "1" "Testar Email de notificação"  \
        "2" "Alterar Email de notificação" \
        "3" "Alterar Hostname"             \
        "4" "Alterar Time Zone do sistema (localtime)" \
        "5" "Instalar programas pré-configurados"      \
        "6" "Configuração de SSH e acesso de ROOT"     \
        "7" "Nível global de Segurança HTTPS/SSL"      \
        "8" "Criar nova Aplicação (usuário Linux)"     \
        "9" "Configurar acesso WEB a uma Aplicação"    \
        3>&1 1>&2 2>&3)
    status=$?
    if [ $status != 0 ]; then
        echo "Seleção cancelada."
        # Na saída precisa verificar o HAproxy se algo mudou
        . /script/info/haproxy.var
        if [ "$HAP_NEW_CONF" == "Y" ]; then
          /script/haproxy.sh --reconfig
        fi
        exit 0
    fi

    # Comando local: enviar Email de teste
    if [ "$MENU_IT" == "1" ];then
      /script/email.sh --test
    fi
    # Comando local: Altera dados do Email de notifucação
    if [ "$MENU_IT" == "2" ]; then
      /script/email.sh
    fi
    # Comando local: alterar hostname
    if [ "$MENU_IT" == "3" ]; then
      /script/hostname.sh
    fi
    # Comando local: alterar Time Zone
    if [ "$MENU_IT" == "4" ]; then
      /script/clock.sh --localtime
    fi
    # Comando local: instalar programas
    if [ "$MENU_IT" == "5" ]; then
      /script/progs.sh
    fi
    # Comando local: alterar SSH e acesso de root
    if [ "$MENU_IT" == "6" ]; then
      /script/ssh.sh
    fi
    # Comando local: alterar SSH e acesso de root
    if [ "$MENU_IT" == "7" ]; then
      /script/haproxy.sh --ssl
    fi
    # Comando local: criar nova Aplicação
    if [ "$MENU_IT" == "8" ]; then
      /script/userapp.sh --newapp
    fi
    # Comando local: Configurar acesso a uma Aplicação
    if [ "$MENU_IT" == "9" ]; then
      /script/userapp.sh --chgapp
    fi
  done # loop menu principal
  return
}

#-----------------------------------------------------------------------

