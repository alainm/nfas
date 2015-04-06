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

