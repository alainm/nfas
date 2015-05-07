#!/bin/bash
# set -x

# Script de inicialização geral, chamadao pelo boot.sh

echo "Parabéns, você está rotando o /script/first.sh"

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
fi

# atualiza todo o sistema
yum -y update
# Repositório auxiliar: https://fedoraproject.org/wiki/EPEL
yum -y install epel-release
# Instalar pacotes extra
yum -y install man nano mcedit telnet bind-utils  \
               openssl openssl-devel pam pam-devel gcc make

# Altera o /etc/rc.d/rc.local para chamar o /script/autostart.sh
cat /etc/rc.d/rc.local | grep "autostart.sh"
if [ $? -ne 0 ]; then
  echo -e "\n# NFAS: executa scripts de inicialização\n/script/autostart.sh\n" >> /etc/rc.d/rc.local
fi

##### Roda cada script de configuração
# Roda as configuraçãoes próprias para o VirtualBox
/script/virtualbox.sh
# Pergunta hostname e configura
/script/hostname.sh --first
# Pergunta dados de Email
/script/email.sh --first
# Cria novo usuário
/script/newuser.sh
# Configura Postfix, usa dados de Email e Hostname
/script/postfix.sh --first
# Monitoramente da máquina
/script/monit.sh --first

# ===== FIM do first.sh =====
# => executa o /script/autostart.sh para iniciar
# /script/autostart.sh

# Lê flag pedindo reboot, pode ter sido setado se precisar
. /script/info/needboot.var
if [ "$NEED_BOOT" == "N" ]; then
  # Não precisa rebootar, mas recomenda
  MSG="\nA instalação está terminada..."
  MSG+="\n\nRecomenda-se rebootar para maior segurança!"
  whiptail --title "Instalação NFAS" --msgbox "$MSG" 11 50
else
  # Precisa rebootar para que as configurações econteçam
  MSG="\nA instalação está terminada..."
  MSG+="\n\nSerá necessário reiniciar para ativar e\nverificar todas as configurações"
  whiptail --title "Instalação NFAS" --msgbox "$MSG" 11 50
  # reboot forçado
  reboot
fi
