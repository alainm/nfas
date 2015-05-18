#
# Arquivo Com funções básicas, incluído por diversos scripts
#

# Uso: atraves do comando ". " (ponto espaço)
# . /script/functions.sh

#-----------------------------------------------------------------------
# Função para extrair IP da saída do ifconfig, deve funcionar sempre (pt, en, arm)
# uso: IP=$(ifconfig eth0 | GetIpFromIfconfig)
function GetIpFromIfconfig(){
  # sed -n '/.*inet /s/ *\(inet *\)\([A-Za-z\.: ]*\)\([\.0-9]*\).*/\3/p'
  sed -n '/.*inet /s/ *inet \+[A-Za-z\.: ]*\([\.0-9]*\).*/\1/p'
}

#-----------------------------------------------------------------------
# Função para testar de network está UP ou DOWN
# uso: NET=$(GetNetworkState eth0)
# retorna na variável "UP" ou "DOWN"
# function GetNetworkState(){
#   ip a | sed -n "/$1:/s/.* state \([A-Z]*\).*/\1/p"
# }

#-----------------------------------------------------------------------
# Função para destecte se ping retorna "Network is unreachable"
# uso: NET_OK=$(NetwokState)
# retorna: "OK"   se network está ok
#          "DOWN" se está deconectado ou DOWN
#          "UN"   se está UP mas está "UNREACHEABLE": problema com route
function GetNetwokState(){
  local ST=$(ip a | sed -n "/eth0:/s/.* state \([A-Z]*\).*/\1/p")
  if [ "$ST" == "DOWN" ]; then
    echo "DOWN"
  else
    local T=$(LANG=C ping -c1 -W1 8.8.8.8 2>&1 | grep 'Network is unreachable')
    if [ -z "$T" ]; then
      echo "OK"
    else
      echo "UN"
    fi
  fi
}

#-----------------------------------------------------------------------
# Função para editar Arquivo de configuração, parametro separado por ":"
# Formato doa parametros: "param:  valor" de separador é ":"
# uso: EditConfColon <Arquivo> <param> <valor>
# usa método de apagar e recriar, é mais seguro!
#   (alguns caracteres poderiam ser interpretados pelo SED)
function EditConfColon(){
  local ARQ=$1
  local PARAM=$2
  local VAL=$3
  if grep -E "^[[:blank:]]*$PARAM[[:blank:]]*:" $ARQ; then
    # linha já existe, precisa apagar antes de criar de novo
    sed -i /^[[:blank:]]*$PARAM[[:blank:]]*:/d $ARQ
  fi
  # linha com parametro não existe, acrescenta linha
  echo "$PARAM:   $VAL" >> $ARQ
}

#-----------------------------------------------------------------------

