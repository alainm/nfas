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

