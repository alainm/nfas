#!/bin/bash

# Este é o script que dá boot na instalação.
# precisa ser feito download e executado manualmente
# penas o mais básico é feito aqui

echo "Executando boot.sh, parabéns..."

# Liga modo de debug: todos os comando são mostrados no console
# set -x

# atualiza todo o sistema
yum -y update

# Determina se está rodando em um VirtualBox
# site: http://stackoverflow.com/questions/12874288/how-to-detect-if-the-script-is-running-on-a-virtual-machine
yum install dmidecode
dmidecode  | grep -i product | grep VirtualBox
if [ $? -eq 0 ] ;then
  IS_VIRTUALBOX="Y"
else
  IS_VIRTUALBOX="N"
fi

# VirtualBox: configura a ETH0 para default sempre ligada
if [ "$IS_VIRTUALBOX" == "Y" ]; then
  sed '/ONBOOT/s/no/yes/g' -i /etc/sysconfig/network-scripts/ifcfg-eth0
fi

# VistualBox: habilita ACPI para fechamento da VM do VitrualBox
# site: http://virtbjorn.blogspot.com.br/2012/12/how-to-make-your-vm-respond-to-acpi.html?m=1
if [ "$IS_VIRTUALBOX" == "Y" ]; then
  yum -y install acpid
  chkconfig acpid on
  service acpid start
fi

# Copia repositório de scrips, o git-clone vai criar um diretório /root/nfas/
yum -y install git
mkdir -p /script
git clone https://github.com/alainm/nfas.git
cp -afv nfas/script/* /script


