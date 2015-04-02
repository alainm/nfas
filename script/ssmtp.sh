#!/bin/bash
# set -x

# Script para (re)configurar o envio de Email usando o SSMTP
# O mesmo Script é usado para a primeira vez e para alterar a configuração
# Chamada: "/script/ssmtp.sh --first" ou "/script/ssmtp.sh --email"
#
# usa as variaveis armazenadas em:
# /script/info/hostname.var
# /script/info/email.var

#-----------------------------------------------------------------------
# Processa a linha de comando
if [ "$1" == "--first" ]; then
  # Chamado pelo Script de instalação inicial
  FIRST="Y"
else
  FIRST="N"
fi
# Lê dados anteriores
. /script/info/hostname.var
. /script/info/email.var

#-----------------------------------------------------------------------
# Instala e faz cópia da configuração original

yum -y install ssmtp


#-----------------------------------------------------------------------
