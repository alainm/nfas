#!/bin/bash
# set -x

# Script para instalar e configurar programas mais comuns
# Uso: /script/prog-node.sh <cmd>
# <cmd>: --first       primeira instalação
#        <sem nada>    Modo interativo, usado pelo nfas

#=======================================================================
# Processa a linha de comando
CMD=$1
# Funções auxiliares
. /script/functions.sh
# Lê dados anteriores se existirem
. /script/info/distro.var
VAR_FILE="/script/info/progs.var"
[ -e $VAR_FILE ] && . $VAR_FILE
TITLE="NFAS - Configuração e Instalaçao do Node.js"

#-----------------------------------------------------------------------
# Verifica se uma versão de Node Existe
function CheckVerNode(){
  local NODE_URL="https://nodejs.org/dist/$1/node-$1-linux-x64.tar.gz"
  if [[ `wget -S --spider $NODE_URL  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
    return 0
  else
    return 1
  fi
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
    echo ""
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
  echo "wget err=$?"
  pushd /usr/local
  tar --strip-components 1 --no-same-owner -xzf /root/$NODE_FILE
  # para Ubuntu: https://github.com/nodesource/distributions#debinstall
  popd
  rm -f /root/$NODE_FILE
  # Mostra versões para debug
  node -v
  npm -v
}

#-----------------------------------------------------------------------
# Pergunta a versão do Node.js
function AskNodeVersion(){
  local FIM N_LIN VER_TMP ERR_MSG
  FIM="N"
  VER_TMP=""
  ERR_MSG=""
  N_LIN=10
  while [ "$FIM" != "Y" ]; do
    MSG="\nQual a versao do Node.js desejada:\n$ERR_MSG"
    VER_TMP=$(whiptail --title "$TITLE" --inputbox "$MSG" $N_LIN 74 $VER_TMP 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      return 1
    else
      # Verifica se tem o "v" na versão...
      [ "${VER_TMP:0:1}" != "v" ] && VER_TMP="v$VER_TMP"
      CheckVerNode $VER_TMP
      if [ $? -eq 0 ]; then
        echo "$VER_TMP"
        return 0
      else
        ERR_MSG="\nERRO: essa versão não foi encontrada, tente novamente"
        ERR_MSG+="\n (verifique versões em https://nodejs.org/dist)"
        N_LIN=13
      fi
    fi
  done
}

#-----------------------------------------------------------------------
# Instala programas pré configurados
function NodeSelect(){
  # Última versão do Node.js:
  local EXE ERR_MSG OPTION
  local LTS_NODE=$(GetVerNodeLts)
  local STB_NODE=$(GetVerNodeStable)
  local CUR_NODE=$(GetVerNodeAtual)
  local VERSAO=""

  while [ "$VERSAO" == "" ]; do
    EXE="whiptail --title \"$TITLE\""
    # Opções de seleção
    if [ "$CUR_NODE" != "" ]; then
      EXE+=" --nocancel --menu \"$ERR_MSG Selecione a versão no NODE que deseja instalar\" 12 75 4 "
      EXE+="\"Atual\"    \"  manter versão atual (recomendado): $CUR_NODE\" "
      EXE+="\"LTS\"      \"  versão LTS                       : $LTS_NODE\" "
    else
      EXE+=" --nocancel --menu \"Selecione a versão no NODE que deseja instalar\" 13 75 3 "
      EXE+="\"LTS\"      \"  versão LTS (recomendado)         : $LTS_NODE\" "
    fi
    EXE+="\"Stable\"     \"  versão latest/stable             : $STB_NODE\" "
    EXE+="\"Custom\"     \"  selecionar a versão manualmente\" "
    OPTION=$(eval "$EXE 3>&1 1>&2 2>&3")
    [ $? != 0 ] && return 1 # Cancelado

    VERSAO="";ERR_MSG=""
    if [ "$OPTION" == "Atual" ]; then
      return
    elif [ "$OPTION" == "LTS" ]; then
      VERSAO="$LTS_NODE"
    elif [ "$OPTION" == "Stable" ]; then
      VERSAO="$STB_NODE"
    elif [ "$OPTION" == "Custom" ]; then
      VERSAO=$(AskNodeVersion)
      [ $? != 0 ] && ERR_MSG="(Erro...)"
    fi
  done

  # Instala ou re-instala o Node.js
  NodeInstall $VERSAO
  # Reinstalou Node.js, precisa reinstalar o Forever
  npm -g install forever
  # Permite execução para "other", não é padrão!!!
  chmod -R o+rx /usr/local/lib/node_modules
}


#-----------------------------------------------------------------------
# main()

if [ "$CMD" == "--first" ]; then
  #--- Primeira instalação
  NodeSelect

#-----------------------------------------------------------------------
else
  #--- Seleciona os programas a instalar
  NodeSelect

fi


