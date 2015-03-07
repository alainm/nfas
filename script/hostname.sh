#!/bin/bash
# set -x

# Script para alterar o nome da máquina: hostname
#  1) Durante instalação: /script/hostname.sh --init
#  2) Alteração interativa, pergunta: /script/hostname.sh
#  3) Modo batch: /script/hostname.sh novo.hostname
# O nome pode ser tanto simples(local) quanto FQDN, isso será tratado pelo sistema
#   a parte antes do primeiro "." é o hostname local, o resto é o domínio, o conjunto todo é o FQDN.
#   Isso não tem nada a ver com o que algum DNS possa estar apontando para a máquina,
#   Só o hostname local é obrigatório, no prompt sempre é só a primeira parte que aparece.
# SEMPRE é atualizada a entrada no /etc/hosts com o IP do eth0 e
# OBS: varia muito conforme o tipo de distro Ubuntu ou CentOS...

# O script básico veio daqui: https://www.centosblog.com/script-update-centos-linux-servers-hostname/
# Site: http://webcache.googleusercontent.com/search?q=cache:CcanLD8maQEJ:serverfault.com/questions/331936/setting-the-hostname-fqdn-or-short-name+&cd=5&hl=pt-BR&ct=clnk&gl=br
# Site: https://github.com/DigitalOcean-User-Projects/Articles-and-Tutorials/blob/master/set_hostname_fqdn_on_ubuntu_centos.md

# Lê Nome e versão da DISTRO
. /script/info/distro.var

# Processa a linha de comando
if [ "$1" == "--first" ]; then
  # Chamado pelo Script de instalação inicial
  FIRST="Y"
else
  FIRST="N"
  # o novo HOSTNAME pode ser fornecido pela linha de comando:
  #   operação automática, sem perguntas
  NEW_HOSTNAME="$1"
fi

# Lê o HOSTNAME atual
OLD_HOSTNAME="$( hostname )"

if [ -z "$NEW_HOSTNAME" ]; then
  if [ "$FIRST" == "Y" ]; then
    MSG="\nQual o NOME da máquina (hostname)?\n"
    MSG+="\n(deixe em branco para \"$OLD_HOSTNAME\" - não recomendado)"
  else
    MSG="\nO hostname atual é: \"$OLD_HOSTNAME\"\n"
    MSG+="Qual o novo hostname?\n"
    MSG+="\n(deixe em branco para não alterar, mas corrige o /etc/hosts)"
  fi
  # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
  NEW_HOSTNAME=$(whiptail --title "Configuração NFAS" --inputbox "$MSG" 11 74  3>&1 1>&2 2>&3)
  if [ $? -ne 0 ]; then
    echo "Operação cancelada!"
    exit 1
  fi
fi

# se está em brando, usa o que já existe
if [ -z "$NEW_HOSTNAME" ]; then
  NEW_HOSTNAME="$OLD_HOSTNAME"
fi

if [ "$NEW_HOSTNAME" == "$OLD_HOSTNAME" ]; then
  echo "Hostname continua sendo \"$OLD_HOSTNAME\", nada a ser feito..."
else
  echo "Alterando hostname de \"$OLD_HOSTNAME\" para \"$NEW_HOSTNAME\""
  # Alterando temporáriamente
  hostname "$NEW_HOSTNAME" &>2 >/dev/null
  if [ $? -ne 0 ]; then
    echo -e "\nERRO: novo hostname é inválido, operação Cancelada!\n"
    exit 2
  fi
  # altera os arquivos releventes para ficar permanente
  if [ "$DISTRO_NAME_VERS" == "CentOS 6" ]; then
    # Só para CentOS: tem que alterar na configuração de Rede
    sed -i "s/HOSTNAME=.*/HOSTNAME=$NEW_HOSTNAME/g" /etc/sysconfig/network
    # ?? precisa reinicar a rede para ter efeito
    # ?? service network restart
  fi
fi

# Altera o arquivo /ETC/HOSTS para ter:
#   <ip> <fqdn> <localhostname>

echo
echo "ATENÇÃO: o prompt só muda após um novo Login !!!"
