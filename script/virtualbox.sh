#!/bin/bash

# Script para ajustes necessários apenas ao VirtualBox
# é chamado pelo /script/first.sh

echo "Rodando o Script de inicialização: /script/virtualbox.sh"

# VirtualBox: configura a ETH0 para default sempre ligada
sed '/ONBOOT/s/no/yes/g' -i /etc/sysconfig/network-scripts/ifcfg-eth0

# VistualBox: habilita ACPI para fechamento da VM do VitrualBox
# site: http://virtbjorn.blogspot.com.br/2012/12/how-to-make-your-vm-respond-to-acpi.html?m=1
yum -y install acpid
chkconfig acpid on
service acpid start

