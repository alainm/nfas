#!/bin/bash
set -x

# Script para ajustes necessários apenas ao VirtualBox
# é chamado pelo /script/first.sh

echo "Rodando o Script de inicialização: /script/virtualbox.sh"

# Determina se está rodando em um VirtualBox
# site: http://stackoverflow.com/questions/12874288/how-to-detect-if-the-script-is-running-on-a-virtual-machine
# A variável fica guardada no diretório de dados, para usar deve ser incluida com o comando ". "
yum -y install dmidecode
dmidecode  | grep -i product | grep VirtualBox
if [ $? -eq 0 ] ;then
  IS_VIRTUALBOX="Y"
else
  IS_VIRTUALBOX="N"
fi
echo "IS_VIRTUALBOX=$IS_VIRTUALBOX" > /script/info/virtualbox.var

# Se não é VirtualBox, retorna sem erro
if [ "$IS_VIRTUALBOX" == "N" ]; then
  exit 0
fi

# VirtualBox: configura a ETH0 para default sempre ligada
sed '/ONBOOT/s/no/yes/g' -i /etc/sysconfig/network-scripts/ifcfg-eth0

# VistualBox: habilita ACPI para fechamento da VM do VitrualBox
# site: http://virtbjorn.blogspot.com.br/2012/12/how-to-make-your-vm-respond-to-acpi.html?m=1
yum -y install acpid
chkconfig acpid on
service acpid start

# Opção para DEBUG: deixar as portas abertas no firewall
MSG="\nVocê está usando o VirtualBox.\n\nDeseja deixar as portas do Firewall abertas para facilitar o Debug?\n"
MSG+="Se responder Sim, todos os serviços estarão acessíveis diretamente\n"
MSG+="\n(Esta opção não aparece fora do VirtualBox!)\n"
# uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail#Yes.2Fno_box
whiptail --title "Configuração NFAS" --yesno --defaultno "$MSG" 13 78
if [ $? -eq 0 ]; then
  echo "OPEN_FIREWALL=Y" >> /script/info/virtualbox.var
else
  echo "OPEN_FIREWALL=N" >> /script/info/virtualbox.var
fi
