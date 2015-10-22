#!/bin/bash
set -x

# Script para instalar e configurar programas mais comuns
# Uso: /script/ssh.sh <cmd>
# <cmd>: --first       primeira instalação
#        --hostname    Alterado hostname, usado por git
#        --email       Alterado Email, usado por git
#        <sem nada>    Modo interativo, usado pelo nfas

#=======================================================================
# Processa a linha de comando
CMD=$1
# Funções auxiliares
. /script/functions.sh
# Lê dados anteriores se existirem
. /script/info/distro.var
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
    MSG+="\n  Criação de arquivos com máscara 0660 para acesso em grupo."
  whiptail --title "$TITLE" --msgbox "$MSG" 13 70
}

#-----------------------------------------------------------------------
# Rotina para instalar Node.js (latest)
function NodeInstall(){
  local NEW_NODE=$(curl --silent --location http://nodejs.org/dist/latest/ | sed -n 's/.*\(node.*linux-x64\.tar\.gz\).*/\1/p')
  echo "Instalar Node: $NEW_NODE"
  # baixa no diretório root
  wget -r http://nodejs.org/dist/latest/$NEW_NODE -O /root/$NEW_NODE
  pushd /usr/local
  tar --strip-components 1 -xzf /root/$NEW_NODE
  popd
  # Mostra versões para debug
  node -v
  npm -v
}

#-----------------------------------------------------------------------
# Instala programas pré configurados
function ProgsInstall(){
  # Última versão do Node.js:
  LAST_NODE="$(curl --silent --location http://nodejs.org/dist/latest/ | sed -n 's/.*\(node.*linux-x64\.tar\.gz\).*/\1/p' | sed -n 's/node-\(v[1-9\.]*\).*/\1/p')"
  NODE_MSG=" versão $LAST_NODE (latest)"
  OPTIONS=$(whiptail --title "$TITLE"                                   \
    --checklist "\nSelecione os programas que deseja Instalar:" 22 75 1 \
    'Node.js' "$NODE_MSG" YES   \
    3>&1 1>&2 2>&3)
  if [ $? == 0 ]; then
    #--- Instala programas selecionados
    for OPT in $(echo $OPTIONS | tr -d '\"'); do
      echo "Instalação: $OPT"
      case $OPT in
        "Node.js")
          NodeInstall
        ;;
      esac
    done
  fi
}
#-----------------------------------------------------------------------
# main()

TITLE="NFAS - Configuração e Instalaçao de Utilitários"
if [ "$CMD" == "--first" ]; then
  #--- Configura o git
  SetupGit
  #--- Seleciona os programas a instalar
  ProgsInstall

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
  #--- Seleciona os programas a instalar
  ProgsInstall
fi
