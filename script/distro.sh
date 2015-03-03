#!/bin/bash
# set -x

# Script para determinar a Distribuição e a Versão
# precisa rodar no começo, antes de instalar qualquer pacote
# somente as versões suportadas são testadas

# Arquivo de Informação gerado
INFO_FILE=/script/info/distro.var

# Pré definição das variáveis que serão geradas, defaults em caso de erro
# Fornece também uma LISTa das Distros suportadas
DISTRO_LIST="CentOS 6"
DISTRO_NAME=""
DISTRO_VERSION=""
DISTRO_OK="N"

# Teste para Ubuntu e outros com LSB
if [ -a /etc/lsb-release ]; then
  DISTRO_NAME=$(cat /etc/lsb-release | sed -n 's/DISTRIB_ID=\(.*\)/\1/p')
  DISTRO_VERSION=$(cat /etc/lsb-release | sed -n 's/DISTRIB_RELEASE=\(.*\)/\1/p')
fi

# Teste do Debian, tem que ser depois do Ubuntu (existe o arquivo no Ubuntu por compatibilidade)
if [ -z "$DISTRO_NAME" ]; then
  if [ -a /etc/debian_version ]; then
    DISTRO_NAME="Debian"
    DISTRO_VERSION=$(cat /etc/debian_version | cut -d'.' -f1)
  fi
fi

# Teste para a família RedHat, testa só o CentoOS
if [ -z "$DISTRO_NAME" ]; then
  # faz um teste com o ls para evitar mensagem de erro
  if [ -n "$(ls /etc/*release* 2>/dev/null)" ]; then
    OS_TMP1=$(cat /etc/*release* | grep -i -m1 centos)
    if [ -n "$OS_TMP1" ]; then
      DISTRO_NAME=$(echo $OS_TMP1 | cut -d' ' -f1)
      DISTRO_VERSION=$(echo $OS_TMP1 | cut -d' ' -f3 | cut -d'.' -f1)
    fi
  fi
fi

if [ -z "$DISTRO_NAME" ]; then
  DISTRO_NAME="Unknown"
  DISTRO_VERSION="?"
fi

if [ "$DISTRO_NAME" == "CentOS" ] && [ "$DISTRO_VERSION" == "6" ]; then
  DISTRO_OK="Y"
fi

echo -e "\nDistribuição encontrada: \"$DISTRO_NAME\" versão \"$DISTRO_VERSION\""

echo "DISTRO_LIST=\"$DISTRO_LIST\""   2>/dev/null >  /script/info/distro.var
echo "DISTRO_NAME=\"$DISTRO_NAME\""   2>/dev/null >> /script/info/distro.var
echo "DISTRO_VERSION=$DISTRO_VERSION" 2>/dev/null >> /script/info/distro.var
echo "DISTRO_OK=$DISTRO_OK"           2>/dev/null >> /script/info/distro.var

if [[ ! -a /script/info/distro.var ]]; then
  echo "ERRO: gravando arquivo /script/info/distro.var"
fi
