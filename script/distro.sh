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
DISTRO_NAME="Unknown"
DISTRO_VERSION=""
DISTRO_OK="N"

# Teste para a família RedHat, testa só o CentoOS
# faz um teste com o ls para evitar mensagem de erro
if [ -n "$(ls /etc/*release* 2>/dev/null)" ]; then
  OS_TMP1=$(cat /etc/*release* | grep -i -m1 centos)
  if [ -n "$OS_TMP1" ]; then
    DISTRO_NAME=$(echo $OS_TMP1 | cut -d' ' -f1)
    if [ "$DISTRO_NAME" == "CentOS" ]; then
      DISTRO_VERSION=$(echo $OS_TMP1 | cut -d' ' -f3 | cut -d'.' -f1)
      if [ "$DISTRO_VERSION" == "6" ]; then
        DISTRO_OK="Y"
      fi
    fi
  fi
fi

echo "DISTRO_LIST="$DISTRO_LIST       >  /script/info/distro.var
echo "DISTRO_NAME="$DISTRO_NAME       >> /script/info/distro.var
echo "DISTRO_VERSION="$DISTRO_VERSION >> /script/info/distro.var
echo "DISTRO_OK="$DISTRO_OK           >> /script/info/distro.var

