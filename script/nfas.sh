#!/bin/bash
# set -x

# === MENU de USUÁRIO ===

# Chamado com o comando: nfas
# permite acesso ás funções de configuração disponíveis pós instalação
# Foi criado um link /usr/bin/nfas para este script

# Lê configurações
. /script/info/email.var

# somente root pode executar este script
if [ "$(id -u)" != "0" ]; then
  echo "Somente root pode executar este comando"
  exit 255
fi
# Loop do Menu principal interativo
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
    /script/newuser.sh --newapp
  fi

  # Comando local: Configurar acesso a uma Aplicação
  if [ "$MENU_IT" == "9" ]; then
    /script/newuser.sh --chgapp
  fi

done # loop menu principal

exit 0

