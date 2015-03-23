#!/bin/bash

# Script executado automáticamente quando reinicia o servidor.
# Chamada pelo /etc/rc.d/rc.local (no CentOS é diferente...)
#
# Essa chamada é configurada quando executa o /script/first.sh

echo "Rodando o Script de inicialização: /script/autostart.sh" > /script/info/autostart.log

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
# quando troca o MAC no CentOS, a placa de rede troca de nome para eth1, eth2, etc.
# elimina informação da placa para evitar a troca de nome, tem que fazer a cada boot
# Só no Virtualbox e CentOS
. /script/info/virtualbox.var
. /script/info/distro.var
if [ "$IS_VIRTUALBOX" == "Y" ] && [ "$DISTRO_NAME" == "CentOS" ]; then
  echo "#" > /etc/udev/rules.d/70-persistent-net.rules
  sed -i /HWADDR/d /etc/sysconfig/network-scripts/ifcfg-eth0
fi

#-----------------------------------------------------------------------
# Executa arquivos no /script/boot na ordem
FILES=$(ls /script/boot/*.sh)
for f in $FILES; do
  echo "Chamando $f" >> /script/info/autostart.log
  # está rodando dentro de um ambiente não padrão (init?), precisa chamar o bash explicitamente
  /bin/bash $f
done


