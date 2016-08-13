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

TITLE="NFAS - Configuração e Instalaçao de Utilitários"
if [ "$CMD" == "--first" ]; then
  #--- Seleciona os programas a instalar
  /script/prog-git.sh --first
  /script/prog-node.sh --first
  ProgsInstall

#-----------------------------------------------------------------------
elif [ "$CMD" == "--hostname" ]; then
  /script/prog-git.sh --hostname

#-----------------------------------------------------------------------
elif [ "$CMD" == "--email" ]; then
  /script/prog-git.sh --email

#-----------------------------------------------------------------------
else
  #--- Seleciona os programas a instalar
  ProgsInstall
fi
