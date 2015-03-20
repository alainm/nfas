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

#-----------------------------------------------------------------------
# Função para extrair IP da saída do ifconfig, deve funcionar sempre (pt, en, arm)
# uso: IP=$(ifconfig eth0 | GetIpFromIfconfig)
function GetIpFromIfconfig(){
  # sed -n '/.*inet /s/ *\(inet *\)\([A-Za-z\.: ]*\)\([\.0-9]*\).*/\3/p'
  sed -n '/.*inet /s/ *inet \+[A-Za-z\.: ]*\([\.0-9]*\).*/\1/p'
}

#-----------------------------------------------------------------------
# Função para perguntar e verificar o HOSTNAME
# Retorna: 0=ok, 1=em branco(intencional) 2=Erro, Aborta de <Cancelar>
function AskHostname(){
  if [ "$FIRST" == "Y" ]; then
    MSG="\nQual o NOME da máquina (hostname)?\n"
    MSG+="\n(deixe em branco para \"$OLD_HOSTNAME\""
    if [ "$NEW_HOSTNAME" == "localhost.localdomain" ]; then
      MSG+="- não recomendado)"
    else
      MSG+=")"
    fi
  else
    MSG="\nO hostname atual é: \"$OLD_HOSTNAME\"\n"
    MSG+="Qual o novo hostname?\n"
    MSG+="\n(deixe em branco para não alterar, mas corrigir o /etc/hosts)"
  fi
  # Acrescenta mensagem de erro
  MSG+="\n$1"
  # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
  NEW_HOSTNAME=$(whiptail --title "Configuração NFAS" --inputbox "$MSG" 13 74  3>&1 1>&2 2>&3)
  if [ $? -ne 0 ]; then
    echo "Operação cancelada!"
    exit 1
  fi
  if [ -z "$NEW_HOSTNAME" ]; then
    echo "Hostname inalterado"
    return 1
  fi
  # Validação do nome
  # Site ajudou: http://www.linuxquestions.org/questions/programming-9/bash-regex-for-validating-computername-872683/
  LC_CTYPE="C"
  # Testa se só tem caracteres válidos
  NEW_HOSTNAME=$(echo $NEW_HOSTNAME | grep -E '^[a-zA-Z][-a-zA-Z0-9_\.]+[a-zA-Z0-9]$')
  # Testa combinações inválidas
  if [ "$NEW_HOSTNAME" != "" ] &&                         # testa se vazio, pode ter sido recusado pela ER...
     [ "$NEW_HOSTNAME" == "${NEW_HOSTNAME//-_/}" ] &&     # testa combinação inválida
     [ "$NEW_HOSTNAME" == "${NEW_HOSTNAME//_-/}" ]; then
    echo "Hostname ok"
    return 0
  else
    echo "Error"
    return 2
  fi
}

#-----------------------------------------------------------------------
# Começo do Script...

# Arquivo de Informação gerado
INFO_FILE=/script/info/hostname.var

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
  # Pergunta o hostname na tela
  ERR=255;   ERR_ST=""
  while [ $ERR -ne 0 ]; do
    AskHostname "$ERR_ST"
    ERR=$?
    if [ $ERR -eq 1 ]; then
      # Hostname em branco intencionalmente
      NEW_HOSTNAME="$OLD_HOSTNAME"
      echo "Hostname continua sendo \"$OLD_HOSTNAME\", nada a ser feito..."
      ERR=0;
    elif [ $ERR -eq 0 ]; then
      # Tenta alterar hostname
      echo "Alterando hostname de \"$OLD_HOSTNAME\" para \"$NEW_HOSTNAME\""
      # Alterando temporáriamente
      hostname $NEW_HOSTNAME &>2 >/dev/null
      if [ $? -ne 0 ]; then
        # Mesmo depois de testado, foi recusado...
        ERR_ST="Nome foi recusado pelo comando \"hostname\", por favor tente novamente"
        ERR=255
      elif [ "$(hostname)" != "$NEW_HOSTNAME" ]; then
        # Mesmo depois de testado, o comando não retornou o que foi programado
        OLD_HOSTNAME="$(hostname)"
        ERR_ST="ATENÇÃO: o hostmane ficou DIFERENTE do desejado, por favor tente novamente"
        ERR=255
      else
        # altera os arquivos relevantes para ficar permanente
        if [ "$DISTRO_NAME_VERS" == "CentOS 6" ]; then
          # Só para CentOS: tem que alterar na configuração de Rede
          sed -i "s/HOSTNAME=.*/HOSTNAME=$NEW_HOSTNAME/g" /etc/sysconfig/network
          # ?? precisa reinicar a rede para ter efeito
          # ?? service network restart
        fi
        # Guarda Hostname fornecido
        echo "HOSTNAME_INFO=\"$NEW_HOSTNAME\""  2>/dev/null >  $INFO_FILE
        # indica que vao precisar de Reboot
        echo "NEED_BOOT=\"Y\""  2>/dev/null >  /script/info/needboot.var
      fi
    else
      ERR_ST="Nome inválido, por favor tente novamente"
    fi
  done
fi

# Altera o arquivo /ETC/HOSTS para ter:
#   <ip> <fullhostname> <localhostname>
NOME_LOCAL=$(hostname -s 2> /dev/null)
NOME_FULL=$(hostname)
[ "$NOME_LOCAL" == "$NOME_FULL" ] && NOME_FULL="" # elimina fqdn se não existe
MY_IP=$(ifconfig eth0 |GetIpFromIfconfig)
if [ -n "$MY_IP" ]; then
  HOSTS_MY_IP=$(cat /etc/hosts | grep "$MY_IP")
  if [ "$NOME_LOCAL" != "localhost" ]; then
    HOSTS_MY_NAME1=$(cat /etc/hosts | grep -v "127.0.0.1" | grep -v "::1" | grep "$NOME_LOCAL")
    HOSTS_MY_NAME2=$(cat /etc/hosts | grep -v "127.0.0.1" | grep -v "::1" | grep "$NOME_FULL")
  else
    HOSTS_MY_NAME1=""; HOSTS_MY_NAME2=""
  fi
  if [ -n "$HOSTS_MY_IP" ]; then
    # já existe uma linha com o IP atual: apaga tudo
    sed -i '/'$MY_IP'/d' /etc/hosts
  fi
  if [ -n "$HOSTS_MY_NAME1" ] || [ -n "$HOSTS_MY_NAME1" ]; then
    # já existe uma linha com este hostname apaga tudo
    sed -i '/'$NOME_LOCAL'/d' /etc/hosts
    if [ -n "$NOME_FULL" ]; then
      sed -i '/'$NOME_FULL'/d' /etc/hosts
    fi
  fi
  if [ "$(echo -e $OLD_HOSTNAME | cut -d '.' -f 1)" != "localhost" ]; then
    # apaga nome antigo se não tinha o mesmo IP
    sed -i '/'$OLD_HOSTNAME'/d' /etc/hosts
  fi
  # Cria linha no /etc/hosts com IP e hostname atuais
  echo -e "$MY_IP\t$NOME_FULL $NOME_LOCAL" >> /etc/hosts
  echo  "Alterando /etc/hosts para \"$MY_IP $NOME_FULL $NOME_LOCAL\""
else
  # Não tem IP na eth0, não faz nada (?)
  echo "ERRO: não foi encontrado IP para a eth0, /etc/hosts não alerado!"
fi

echo
echo "ATENÇÃO: o prompt só muda após um novo Login !!!"
