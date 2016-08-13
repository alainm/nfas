#!/bin/bash
set -x

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
  return $?
  pushd /usr/local
  tar --strip-components 1 --no-same-owner -xzf /root/$NODE_FILE
  # para Ubuntu: https://github.com/nodesource/distributions#debinstall
  popd
  # Mostra versões para debug
  node -v
  npm -v
}

#-----------------------------------------------------------------------
# Instala programas pré configurados
function NodeSelect(){
  # Última versão do Node.js:
  local EXE MSG ERR_MSG OPTION FIM VERSAO VER_TMP
  local LTS_NODE=$(GetVerNodeLts)
  local STB_NODE=$(GetVerNodeStable)
  local CUR_NODE=$(GetVerNodeAtual)

  EXE="whiptail --title \"$TITLE\""
  # Opções de seleção
  if [ "$CMD" != "--first" ] || [ "$CUR_NODE" == "" ]; then
    EXE+=" --nocancel --radiolist \"Selecione a versão no NODE que deseja instalar\" 12 75 4 "
    EXE+="\"Atual\"    \"manter versão atual (recomendado): $CUR_NODE\" YES "
    EXE+="\"LTS\"      \"versão LTS                       : $LTS_NODE\" NO "
  else
    EXE+=" --nocancel --radiolist \"Selecione a versão no NODE que deseja instalar\" 13 75 3 "
    EXE+="\"LTS\"      \"versão LTS (recomendado)         : $LTS_NODE\" YES "
  fi
  EXE+="\"Stable\"     \"versão latest/stable             : $STB_NODE\" NO "
  EXE+="\"Custom\"     \"selecionar a versão manualmente\" NO "
  OPTION=$(eval "$EXE 3>&1 1>&2 2>&3")
  [ $? != 0 ] && return 1 # Cancelado

  VERSAO=""
  if [ "$OPTION" == "Custom" ]; then
    FIM="N"
    VER_TMP=""
    ERR_MSG=""
    while [ "$FIM" != "Y" ]; do
      MSG="\nQual a versao do Node.js desejada:$ERR_MSG"
      VER_TMP=$(whiptail --title "$TITLE" --inputbox "$MSG" 10 74 $VER_TMP 3>&1 1>&2 2>&3)
      if [ $? -ne 0 ]; then
        FIM="Y"
      else
        # Verifica se tem o "v" na versão...
        [ "${VER_TMP:0:1}" != "v" ] && VER_TMP="v$VER_TMP"
        CheckVerNode $VER_TMP
        if [ $? -eq 0 ]; then
          VERSAO="$VER_TMP"
          FIM="Y"
        else
          ERR_MSG="\nERRO: essa versão não foi encontrada, tente novamente"
        fi
      fi
    done
  elif [ "$OPTION" == "Atual" ]; then
    VERSAO="$CUR_NODE"
  elif [ "$OPTION" == "LTS" ]; then
    VERSAO="$LTS_NODE"
  elif [ "$OPTION" == "Stable" ]; then
    VERSAO="$STB_NODE"
  fi

return 0
  OPTIONS=$(echo $OPTIONS | tr -d '\"')
  if [ $? == 0 ]; then
    #--- Instala programas selecionados
    echo "Opt list=[$OPTIONS]"
    for OPT in $OPTIONS; do
      echo "Instalação: $OPT"
      case $OPT in
        "Node-LTS")
          if echo "$OPTIONS" | grep -q "Node-Stable"; then
            echo "Não instala as duas versões"
          else
            NodeInstall $LTS_NODE
          fi
        ;;
        "Node-Stable")
          # Evita instalar as duas versões
          if [ "$NODE_LTS" != "Y" ]; then
            NodeInstall $STB_NODE
          fi
        ;;
      esac
    done # for OPT
    if echo "$OPTIONS" | grep -q "Node-LTS\|Node-Stable"; then
      # Reinstalou Node.js, precisa reinstalar o Forever
      npm -g install forever
      # Permite execução para "other", não é padrão!!!
      chmod -R o+rx /usr/local/lib/node_modules
    fi
  fi
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


