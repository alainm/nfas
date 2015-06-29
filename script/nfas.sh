#!/bin/bash
# set -x

# === MENU de USUÁRIO ===

# Chamado com o comando: nfas
# permite acesso ás funções de configuração disponíveis pós instalação
# Foi criado um link /usr/bin/nfas para este script

# Lê configurações
. /script/info/email.var

# Mostra Menu
MENU_IT=$(whiptail --title "NFAS - Node.js Full Application Server" \
    --menu "Selecione um comando de reconfiguração:" --fb 18 70 4   \
    "1" "Testar Email de notificação"  \
    "2" "Alterar Hostname"             \
    "3" "Alterar Email de notificação" \
    "4" "Criar novo Usuário/aplicação" \
    3>&1 1>&2 2>&3)
status=$?
if [ $status != 0 ]; then
    echo "Seleção cancelada."
    exit 1
fi

# Comando local: enviar Email de teste
if [ "$MENU_IT" == "1" ];then
  echo "Testar Email de Notificação"
  echo "  Email enviado para admin: $EMAIL_ADMIN"
  echo "  usando servidor SMTP:     $EMAIL_SMTP_URL"
  echo "  e usuário:                $EMAIL_USER_ID"
  MSG="\nEnviado por Hostname: \"$(hostname -f)\""
  MSG+="\n para: $EMAIL_ADMIN"
  MSG+="\n\nServidor SMTP: $EMAIL_SMTP_URL"
  MSG+="\n usuário:      $EMAIL_USER_ID"
  MSG+="\n\nEnviado em: $(date +"%d/%m/%Y %H:%M:%S (%Z %z)")"
  echo -e $MSG | mail -s "Teste de Notificação" $EMAIL_ADMIN
  exit 0
fi

# Chama cada comando
[ "$MENU_IT" == "2" ] && echo "Alterar Hostname, não implementado"
[ "$MENU_IT" == "3" ] && echo "Alterar email, não implementado"
[ "$MENU_IT" == "4" ] && echo "Novo Usuário, não implementado"

exit 0


