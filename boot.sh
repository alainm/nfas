#!/bin/bash

# Este é o script que dá boot na instalação.
# precisa ser feito download e executado manualmente
# penas o mais básico é feito aqui

echo "Executando boot.sh, parabéns..."

# Configura a ETH0 para default sempre ligada
sed '/ONBOOT/s/no/yes/g' -i /etc/sysconfig/network-scripts/ifcfg-eth0

# Habilita ACPI para fechamento da VM do VitrualBox
# site: http://virtbjorn.blogspot.com.br/2012/12/how-to-make-your-vm-respond-to-acpi.html?m=1
# TODO: bom para VirtualBox, verificar viabilidade para VPS
yum -y install acpid
chkconfig acpid on
service acpid start
