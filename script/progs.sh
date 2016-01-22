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
    MSG+="\n  Criação de arquivos com máscara 660 para acesso em grupo."
  whiptail --title "$TITLE" --msgbox "$MSG" 13 70
}

#-----------------------------------------------------------------------
# Fornece a versão do Node Stable mais novo
function GetVerNodeStable(){
  # usa o WGET com "--no-dns-cache -4" para melhorar a velocidade de conexão
  local NEW_NODE=$(wget --quiet --no-dns-cache -4 http://nodejs.org/dist/latest/ -O - | sed -n 's/.*\(node.*linux-x64\.tar\.gz\).*/\1/p' | sed -n 's/node-\(v[0-9\.]*\).*/\1/p')
  echo "$NEW_NODE"
}

#-----------------------------------------------------------------------
# Fornece a versão do Node LTS mais novo
# procura na tabela em https://nodejs.org/dist/index.tab
#   foi dica daqui: https://github.com/nodejs/node/issues/4569#issuecomment-169746908
function GetVerNodeLts(){
  # Baixa lista oficial de versões, coluna1: versão, coluna10: novme lts,
  #   tira primeira linha header, só linhas co nome Lts, sort, última linha, versão
  local LTS_NODE=$(wget --quiet --no-dns-cache -4 https://nodejs.org/dist/index.tab -O - | awk '{print $1 "\t" $10}' | tail -n +2 | \
    awk '$2 != "-"' | sort | tail -n 1 | cut -f1)
  echo "$LTS_NODE"
}

#-----------------------------------------------------------------------
# Fornece a versão atual do Node instalada
function GetVerNodeAtual(){
  if which node >/dev/null; then
    echo $(node -v)
  else
    echo "não instalado"
  fi
}

#-----------------------------------------------------------------------
# Rotina para instalar Node.js (latest)
# site: https://nodejs.org/dist/v4.2.6/node-v4.2.6-linux-x64.tar.gz
# Uso: NodeInstall <versão>
function NodeInstall(){
  # Localização e nome do arquivo da versão solicitada
  local NODE_URL="https://nodejs.org/dist/$1/node-$1-linux-x64.tar.gz"
  local NODE_FILE="node-$1-linux-x64.tar.gz"
  echo "Instalar Node: $NODE_FILE"
  # baixa no diretório root
  wget --no-dns-cache -4 -r $NODE_URL -O /root/$NODE_FILE
  pushd /usr/local
  tar --strip-components 1 -xzf /root/$NODE_FILE
  popd
  # Mostra versões para debug
  node -v
  npm -v
}

#-----------------------------------------------------------------------
# Instala programas pré configurados
function ProgsInstall(){
  # Última versão do Node.js:
  local LTS_NODE=$(GetVerNodeLts)
  local STB_NODE=$(GetVerNodeStable)
  local NODE1_MSG="versão LTS          : $LTS_NODE. atual=$(GetVerNodeAtual)"
  local NODE2_MSG="versão latest/stable: $STB_NODE"
  local OPTIONS=$(whiptail --title "$TITLE"                                   \
    --checklist "\nSelecione os programas que deseja Instalar:" 22 75 2 \
    'Node-LTS'    "$NODE1_MSG" YES   \
    'Node-Stable' "$NODE2_MSG" NO    \
    3>&1 1>&2 2>&3)
  if [ $? == 0 ]; then
    #--- Instala programas selecionados
    for OPT in $(echo $OPTIONS | tr -d '\"'); do
      echo "Instalação: $OPT"
      case $OPT in
        "Node-LTS")
          NodeInstall $LTS_NODE
        ;;
        "Node-Stable")
          NodeInstall $STB_NODE
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
