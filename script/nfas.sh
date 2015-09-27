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
      --menu "Selecione um comando de reconfiguração:" --fb 18 70 4   \
      "1" "Testar Email de notificação"  \
      "2" "Alterar Email de notificação" \
      "3" "Alterar Hostname"             \
      "4" "Configuração de SSH e acesso de ROOT" \
      3>&1 1>&2 2>&3)
  status=$?
  if [ $status != 0 ]; then
      echo "Seleção cancelada."
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

  # Comando local: alterar hostname
  if [ "$MENU_IT" == "4" ]; then
    /script/ssh.sh
  fi
done # loop menu principal

exit 0


