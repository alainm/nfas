#!/bin/bash
set -x

# Script para instalar e configurar o GIT
# Uso: /script/prog-git.sh <cmd>
# <cmd>: --first       primeira instalação
#        --hostname    Alterado hostname, usado por git
#        --email       Alterado Email, usado por git
#        <sem nada>    Não faz nada!

#=======================================================================
# Processa a linha de comando
CMD=$1
# Lê dados anteriores se existirem
. /script/info/hostname.var
. /script/info/email.var
VAR_FILE="/script/info/progs.var"
[ -e $VAR_FILE ] && . $VAR_FILE

#-----------------------------------------------------------------------
# Rotina para configurar o GIT
# faz apenas a configuração global de email e usuário=hostname
function SetupGit(){
  local MSG
  # Configura mesmo email que sistema
  git config --global user.email "$EMAIL_ADMIN"
  # Configura hostname como nome default
  git config --global user.name "$HOSTNAME_INFO"
  # Faz o git criar arquivos com acesso de grupo
  git config --global core.sharedRepository 0660
  # Mensagem de aviso informativo
     MSG=" Instalados utilitários de compilação: GCC, Make, etc.."
  MSG+="\n\nGIT foi instalado e configurado:"
    MSG+="\n  Nome e Email globais iguais ao do administrador,"
    MSG+="\n  Criação de arquivos com máscara 660 para acesso em grupo."
  whiptail --title "$TITLE" --msgbox "$MSG" 13 70
}

#-----------------------------------------------------------------------

TITLE="NFAS - Configuração e Instalaçao do GIT"
if [ "$CMD" == "--first" ]; then
  #--- Configura o git
  SetupGit

#-----------------------------------------------------------------------
elif [ "$CMD" == "--hostname" ]; then
  # Re-configura hostname como nome default
  git config --global user.name "$HOSTNAME_INFO"

#-----------------------------------------------------------------------
elif [ "$CMD" == "--email" ]; then
  # Re-configura mesmo email que sistema
  git config --global user.email "$EMAIL_ADMIN"

#-----------------------------------------------------------------------
else
  #--- não faz nada!

fi

