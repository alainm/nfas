#!/bin/bash
set -x

# Identifica se está rodando no VirtualBox
# Ajustes necessários apenas ao VirtualBox
# é chamado pelo /script/first.sh
# Chamada: "/script/virtualbox.sh <cmd>"
# <cmd>: --first          durante primeira instalação
#
# SAÍDA com errorleve==1 se deve abortar a instalação


#-----------------------------------------------------------------------
# Processa a linha de comando
CMD=$1
# Arquivo de Informação gerado
VAR_FILE=/script/info/virtualbox.var
# Lê dados anteriores, se existirem
[ -e $VAR_FILE ] && . $VAR_FILE
. /script/info/distro.var

#-----------------------------------------------------------------------
# Salva variáveis de informações coletadas, outros pacotes vão utilizar
function SaveVBoxVars(){
  # Verifica se variáveis existem, só a primeira é garantida
  [ -z "$IS_VIRTUALBOX" ] && IS_VIRTUALBOX="N"
  [ -z "$OPEN_FIREWALL" ] && OPEN_FIREWALL="N"
  echo "IS_VIRTUALBOX=$IS_VIRTUALBOX"        2>/dev/null >  $VAR_FILE
  echo "OPEN_FIREWALL=$OPEN_FIREWALL"        2>/dev/null >> $VAR_FILE
}

#=======================================================================

if [ "$CMD" == "--first" ]; then
  #----- Determina se está rodando em um VirtualBox
  # site: http://stackoverflow.com/questions/12874288/how-to-detect-if-the-script-is-running-on-a-virtual-machine
  # A variável fica guardada no diretório de dados, para usar deve ser incluida com o comando ". "
  # yum -y install dmidecode => foi para o first.sh
  dmidecode  | grep -i product | grep VirtualBox
  if [ $? -eq 0 ] ;then
    IS_VIRTUALBOX="Y"
  else
    IS_VIRTUALBOX="N"
  fi
  #----- Se não é VirtualBox, retorna sem erro: sempre continua a instalação
  if [ "$IS_VIRTUALBOX" == "N" ]; then
    # Guarda informação, outros pacotes vão utilizar
    SaveVBoxVars
    exit 0
  fi

  #----- No CentOS a Rede vem desabilitada por default, precisa habilitar
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    # VirtualBox: configura a ETH0 para default sempre ligada
    sed '/ONBOOT/s/no/yes/g'        -i /etc/sysconfig/network-scripts/ifcfg-eth0
    sed '/NM_CONTROLLED/s/yes/no/g' -i /etc/sysconfig/network-scripts/ifcfg-eth0
    # VistualBox: habilita ACPI para fechamento da VM do VitrualBox
    # site: http://virtbjorn.blogspot.com.br/2012/12/how-to-make-your-vm-respond-to-acpi.html?m=1
    # movido para first.sh: yum -y install acpid
    chkconfig acpid on
    service acpid start
  else
    echo "Virtualbox + Ubuntu não implementado"
  fi

  #----- Pergunta se deve abortar a instalação, serve para criar imagem da VM
  # para abortar retorna com {exit 1} para sinalizar no firts.sh
      MSG=" Todos os pacotes foram atualizados e/ou instalados"
    MSG+="\nDeseja abortar a instalação para salvar uma imagem?"
  MSG+="\n\n(Esta opção não aparece fora do VirtualBox!)"
  # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail#Yes.2Fno_box
  whiptail --title "Configuração NFAS" --yesno --defaultno "$MSG" 10 78
  if [ $? -eq 0 ]; then
    # Guarda informação, outros pacotes vão utilizar
    SaveVBoxVars
    # Aborta instalação e mantém imagem do VirtualBox
    exit 1
  fi

  #----- Opção para DEBUG: deixar as portas abertas no firewall
  MSG="\nVocê está usando o VirtualBox.\n\nDeseja deixar as portas do Firewall abertas para facilitar o Debug?\n"
  MSG+="Se responder Sim, todos os serviços estarão acessíveis diretamente\n"
  MSG+="\n(Esta opção não aparece fora do VirtualBox!)"
  # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail#Yes.2Fno_box
  whiptail --title "Configuração NFAS" --yesno "$MSG" 13 78
  if [ $? -eq 0 ]; then
    OPEN_FIREWALL="Y"
  else
    OPEN_FIREWALL="N"
  fi

  #----- Guarda informação, outros pacotes vão utilizar
  SaveVBoxVars

fi

# retorna errorlevel para continuar
exit 0

#-----------------------------------------------------------------------
