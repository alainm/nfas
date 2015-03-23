#!/bin/bash

# Script executado automáticamente quando reinicia o servidor.
# Chamada pelo /etc/rc.d/rc.local (no CentOS é diferente...)
#
# Essa chamada é configurada quando executa o /script/first.sh

echo "Rodando o Script de inicialização: /script/autostart.sh"

# Inclui funções básicas
. /script/functions.sh

#-----------------------------------------------------------------------
# Mostra IP na tela de boot
#
MY_IP=$(ifconfig eth0 |GetIpFromIfconfig)
MSG="\n IP atual:"
if [ -z "$(sed -n '/IP atual/p' /etc/issue)" ]; then
  # primeira vez
  echo -e " IP atual: $MY_IP\n" >> /etc/issue
else
  # altera existente
  sed -i "s/\(^[[:blank:]]*IP atual[[:blank:]]*:\)\(.*\)/\1 $MY_IP/" /etc/issue
fi

#-----------------------------------------------------------------------
# Executa arquivos no /script/boot na ordem
FILES=$(ls /script/boot/*.sh)
for f in $FILES; do
  echo "Processing $f"
  $f
done


