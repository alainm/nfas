#!/bin/bash
# set -x

# Script de inicialização geral, chamadao pelo boot.sh

echo "Parabéns, você está rodando o /script/first.sh"

# Diretório de informações coletadas
mkdir -p /script/info
echo "NEED_BOOT=\"N\""  2>/dev/null >  /script/info/needboot.var

# Primeiro verifica se a Distribuição é compatível,
# executa o script e importa as variáveis resultantes
/script/distro.sh
. /script/info/distro.var
if [ "$DISTRO_OK" != "Y" ]; then
  MSG="A distribuição encontrada é \"$DISTRO_NAME\" versão \"$DISTRO_VERSION\"\n"
  MSG="$MSG""As vesrões compatíveis são: \"$DISTRO_LIST\"\n\n   Abortando instalação..."
  whiptail --title "Instalação NFAS" --msgbox "\"$MSG"\" 11 60
  exit 1
else
  MSG="A distribuição encontrada é \"$DISTRO_NAME\" versão \"$DISTRO_VERSION\"\n\n"
  MSG+="Acione OK para começar a instalação"
  whiptail --title "Instalação NFAS" --msgbox "\"$MSG"\" 11 60
fi

# atualiza todo o sistema
yum -y update
# Repositório auxiliar: https://fedoraproject.org/wiki/EPEL
yum -y install epel-release
# Instalar pacotes extra
PKT="man nano mcedit mc telnet bind-utils bc mlocate"
PKT+=" openssl openssl-devel pam pam-devel gcc gcc-c++ make git"
# pacote para ajudar a identificar o VirtualBox
PKT+=" dmidecode"
# instala programas pequenos e úteis: htop nmon
PKT+=" htop nmon"
# pacotes para compilar MONIT e dependencias
PKT+=" openssl openssl-devel pam pam-devel gcc make"
# pacotes para POSTFIX (para Ubuntu: libsasl2-modules)
PKT+=" mailx cyrus-sasl-plain postfix-perl-scripts"
# Pacote para fail2ban
PKT+=" fail2ban jwhois"
# Pacote para relógio
PKT+=" ntp"
yum -y install $PKT

# Cria banco de dados para locate, varre todos os nomes de arquivos
updatedb

# Altera o /etc/rc.d/rc.local para chamar o /script/autostart.sh
cat /etc/rc.d/rc.local | grep "autostart.sh"
if [ $? -ne 0 ]; then
  echo -e "\n# NFAS: executa scripts de inicialização\n/script/autostart.sh\n" >> /etc/rc.d/rc.local
fi

# Cria link para menu do usuário
ln -s /script/nfas.sh /usr/bin/nfas

##### Roda cada script de configuração
# Roda as configuraçãoes próprias para o VirtualBox
/script/virtualbox.sh
# Pergunta hostname e configura
/script/hostname.sh --first
# Console colorido
/script/console.sh --first
# Configura Postfix, usa Hostname mas não Email
/script/postfix.sh --first
# Pergunta dados de Email
/script/email.sh --first
# Configurações e alterações na Rede
/script/network.sh --first
# Monitoramente da máquina, tem que vir depois do hostname.sh e email.sh
/script/monit.sh --first
# Setup do relógio
/script/clock.sh --first
# Configurações de SSH e acesso de ROOT
/script/ssh.sh --first
# Instala programas
/script/progs.sh --first
# Cria novo usuário
/script/newuser.sh

# ===== FIM do first.sh =====
# => executa o /script/autostart.sh para iniciar
# /script/autostart.sh

# Lê flag pedindo reboot, pode ter sido setado se precisar
. /script/info/needboot.var
# if [ "$NEED_BOOT" == "N" ]; then
#   # Não precisa rebootar, mas recomenda
#   MSG="\nA instalação está terminada..."
#   MSG+="\n\nRecomenda-se rebootar para maior segurança!"
#   whiptail --title "Instalação NFAS" --msgbox "$MSG" 11 50
# else
  # Precisa rebootar para que as configurações econteçam
  MSG="\nA instalação está terminada..."
  MSG+="\n\nSerá necessário reiniciar para ativar e\nverificar todas as configurações"
  whiptail --title "Instalação NFAS" --msgbox "$MSG" 11 50
  # reboot forçado
  reboot
# fi
