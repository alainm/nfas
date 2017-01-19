#!/bin/bash
# set -x

# Script de inicialização geral, chamadao pelo boot.sh
# Chamada:
# /script/first.sh                Faz a primeira instalação
# /script/first.sh --ip-continue  Continua instalação interrompida por troca de IP

# Inclui funções básicas
. /script/functions.sh

echo "Parabéns, você está rodando o /script/first.sh"

# Pode ser continuação de instalação interrompida pela troca de IP
if [ "$1" != "--ip-continue" ]; then

  # Diretório de informações coletadas
  mkdir -p /script/info
  echo "NEED_BOOT=\"N\""  2>/dev/null >  /script/info/needboot.var

  # Primeiro verifica se a Distribuição é compatível,
  # executa o script e importa as variáveis resultantes
  /script/distro.sh
  . /script/info/distro.var
  MSG=" A distribuição encontrada é: \"$DISTRO_NAME $DISTRO_VERSION $DISTRO_BITS bits\"\n\n"
  if [ "$DISTRO_OK" != "Y" ]; then
    MSG="$MSG""As vesrões compatíveis são:  \"$DISTRO_LIST\"\n\n   Abortando instalação..."
    whiptail --title "Instalação NFAS" --msgbox "$MSG" 11 67
    exit 1
  else
    MSG+="\nAcione OK para começar a instalação"
    whiptail --title "Instalação NFAS" --msgbox "$MSG" 11 67
  fi

  # atualiza todo o sistema
  yum -y update
  # Repositório auxiliar: https://fedoraproject.org/wiki/EPEL
  yum -y install epel-release
  # Instalar pacotes extra
  PKT="man nano mc telnet bind-utils bc mlocate dialog"
  PKT+=" openssl openssl-devel pam pam-devel gcc gcc-c++ make git"
  # pacote para ajudar a identificar o VirtualBox
  PKT+=" dmidecode acpid"
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
  # Pacotes para o HAproxy e Lua
  PKT+=" pcre-devel readline-devel"
  # Pacode de administração do SElinux (usado para o MongoDB e outros)
  PKT+=" policycoreutils-python"
  yum -y install $PKT

  if [ $? -ne 0 ]; then
       MSG=" Ocorreu um erro atualizando pacotes."
    MSG+="\n\nSua conexão deve estar com problemas,"
      MSG+="\n  tente novamente mais tarde..."
    whiptail --title "Instalação NFAS" --msgbox "$MSG" 11 60
    exit 1
  fi

  # Cria banco de dados para locate, varre todos os nomes de arquivos
  updatedb

  ##### Roda cada script de configuração
  # Roda as configuraçãoes próprias para o VirtualBox
  /script/virtualbox.sh --first
  # aborta instalação e preserva a VM
  [ $? -ne 0 ] && exit 1
  # Verifica se roote tem senha e pergunta
  /script/userapp.sh --root-pwd
  # Console colorido, precisa executar como usuário
  chmod 775 /script/console.sh
  chmod o+r /script/functions.sh
  /script/console.sh --first
  # Configurações e alterações na Rede
  /script/network.sh --first
  # Configura Postfix, usa Hostname mas não Email
  /script/postfix.sh --first
  # Pergunta se quer IP fixo, so se VirtualBox. Encerra se reboot
  /script/network.sh --ipfixo
  [ $? -ne 0 ] && exit 1
else
  # Deslifa flag de continuação
  EditConfEqualSafe /script/info/network.var NEW_IP_CONTINUE N
  MSG="\n Continuando a instalação..."
  MSG+="\n\n                   ...depois da troca de IP"
  whiptail --title "Instalação NFAS" --msgbox "$MSG" 11 50
fi # --ip-continue
# Pergunta hostname e configura
/script/hostname.sh --first
# Setup do relógio
/script/clock.sh --first
# Executa scripts de boot: Firewall, etc...
/script/autostart.sh --first
# Pergunta dados de Email
/script/email.sh --first
# Monitoramente da máquina, tem que vir depois do hostname.sh e email.sh
/script/monit.sh --first
# Configurações de SSH e acesso de ROOT
/script/ssh.sh --first
# Instala e configura Proxy Reverso
/script/haproxy.sh --first
# Instala programas
/script/progs.sh --first
# Cria novo usuário
/script/userapp.sh --first
# Reconfigura HAproxy caso haja alguma alteração pendente
. /script/info/haproxy.var
if [ "$HAP_NEW_CONF" == "Y" ]; then
  /script/haproxy.sh --reconfig
fi
#read -p "Pressione qualquer tecla para continuar" A

# Altera o /etc/rc.d/rc.local para chamar o /script/autostart.sh
cat /etc/rc.d/rc.local | grep "autostart.sh"
if [ $? -ne 0 ]; then
  echo -e "\n# NFAS: executa scripts de inicialização\n/script/autostart.sh\n" >> /etc/rc.d/rc.local
fi

# Cria link para menu do usuário
ln -s /script/nfas.sh /usr/bin/nfas

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
