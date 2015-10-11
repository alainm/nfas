#!/bin/bash
set -x

# Script para criar um novo usuário
# Uso: /script/newuser.sh
# <cmd>: --first       primeira instalação
#        <em branco>   modo interativo

#=======================================================================
# Processa a linha de comando
CMD=$1
# Funções auxiliares
. /script/functions.sh
. /script/info/distro.var

#-----------------------------------------------------------------------
# Função para perguntar e verificar nome da aplicação
# uso: AskName <VAR> "Tipo de nome"
# VAR é a variável que vai receber o Email
# NOME é para mostrar na tela
# Retorna: 0=ok, 1=Aborta se <Cancelar>
function AskName(){
  local VAR=$1
  local SHOW=$2
  local TMP=""
  local ERR_ST=""
  local NAME_TMP
  # pega valor anterior do Email
  eval TMP=\$$VAR
  # loop só sai com return
  while true; do
    MSG="\nQual o $SHOW (deve ser válido com usuário Linux)?\n"
    if [ -n "$TMP" ]; then
      MSG+="\n<Enter> para manter o anterior sendo mostrado\n"
    fi
    # Acrescenta mensagem de erro
    MSG+="\n$ERR_ST"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    TMP=$(whiptail --title "$"TITLE --inputbox "$MSG" 13 74 $TMP 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operação cancelada!"
      return 1
    fi
    # Testa se só tem caracteres válidos
    # http://serverfault.com/questions/73084/what-characters-should-i-use-or-not-use-in-usernames-on-linux
    NAME_TMP=$(echo $TMP | grep -E '^[a-zA-Z0-9_][a-zA-Z0-9_-.]*[a-zA-Z0-9_]$')
    # Testa combinações inválidas
    if [ "$NAME_TMP" != "" ] &&        # testa se vazio, pode ter sido recusado pela ER...
       [ "$NAME_TMP" == "$TMP" ]; then # Não foi alterado pela ER
      # Nome aceito, Continua
      eval "$VAR=$TMP"
      return 0
    else
      ERR_ST="Nome inválido, por favor tente novamente"
    fi
  done

}

#-----------------------------------------------------------------------
# Função para perguntar e verificar uma Senha
# uso: AskName <VAR> "Tipo de senha"
# VAR é a variável que vai receber o Email
# NOME é para mostrar na tela
# Retorna: 0=ok, 1=Aborta se <Cancelar>
function AskPasswd(){
  local VAR=$1
  local SHOW=$2
  local MSG
  local TMP=""
  local ERR_ST=""
  local PWD_TMP
  # pega valor anterior do Email
  eval TMP=\$$VAR
  # loop só sai com return
  while true; do
    MSG="\nQual a senha de $SHOW (use senha segura...)?"
    MSG+="\n Caracteres válidos: a-zA-Z0-9!@#$%^&*()_-+={};:,./?"
    # Acrescenta mensagem de erro
    MSG+="\n\n$ERR_ST"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    PWD1=$(whiptail --passwordbox --title "$"TITLE  "$MSG" 13 70 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operação cancelada!"
      return 1
    fi
    MSG="\nDigite novamente a senha para verificação\n\n\n"
    PWD2=$(whiptail --passwordbox --title "$"TITLE  "$MSG" 13 70 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operação cancelada!"
      return 1
    fi
    if [ "$PWD1" != "$PWD2" ]; then
      ERR_ST="Senhas não são identicas, favor repetir a operação"
    else
      # Testa se só tem caracteres válidos
      echo $PWD1 | grep -E '^[a-zA-Z0-9!@#$%^&*()_-+=\{\};:,./?]+$'
      if [ $? -eq 0 ]; then
        # Nome aceito, Continua
        eval "$VAR=$PWD1"
        return 0
      else
        ERR_ST="Senha inválida, por favor tente novamente"
      fi
    fi
  done
}

#-----------------------------------------------------------------------
# Rotina para Criar uma Aplicação (usuário Linux)
function NewApp(){
  local NEW_NAME, NEW_PWD
  AskName NEW_NAME "Nome da Aplicação"
  [ $? != 0 ] && return 1
  AskPasswd NEW_PWD "Senha do usuário Aplicação"
  [ $? != 0 ] && return 1
  echo "Nova Aplicação: $NEW_NAME, passwd: $NEW_PWD"
  # criando usuários
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    useradd $NEW_NAME
    echo "$NEW_PWD" | passwd --stdin $NEW_NAME
  else
    # OBS: useradd não cria o home directory no Ubuntu 14.04, só com "-m"
    useradd -m $NEW_NAME
    # OBS: --stdin só funciona no CentOS (não no Ubuntu 14.04)
    echo "$NEW_PWD" | passwd --stdin $NEW_NAME
  fi
  /script/console.sh --newuser $NEW_NAME
  cp -a /script/auto.sh /home/$NEW_NAME
  chown $NEW_NAME:$NEW_NAME /home/$NEW_NAME/auto.sh
}

#-----------------------------------------------------------------------
# main()

TITLE="NFAS - Configuração de Aplicações e Usuários"
if [ "$CMD" == "--first" ]; then
  NewApp


#-----------------------------------------------------------------------
else
  # Loop do Menu principal interativo
  while true; do
    MENU_IT=$(whiptail --title "NFAS - Node.js Full Application Server" \
        --menu "Selecione um comando de reconfiguração:" --fb 18 70 5   \
        "1" "Criar nova Aplicação (usuário Linux)"  \
        "2" "Configurar a Aplicação" \
        3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
        echo "Seleção cancelada."
        exit 0
    fi

    # Comando local: Nova aplicação
    if [ "$MENU_IT" == "1" ];then
      NewApp
    fi
    # Comando local: Configurar aplicação
    if [ "$MENU_IT" == "2" ];then
      ConfigApp
    fi

  done # loop menu principal

fi

exit 0
# >>>> PROVISÓRIO <<<<
# necessário apenas para testar os outros recursos

# criando usuários
# OBS: --stdin só funciona no CentOS (não no Ubuntu 14.04)
# OBS: useradd não cria o home directory no Ubuntu 14.04, só com "-m"
useradd teste1
echo "node1" | passwd --stdin teste1
/script/console.sh --newuser teste1
cp -a /script/auto.sh /home/teste1
chown teste1:teste1 /home/teste1/auto.sh

useradd teste2
echo "node2" | passwd --stdin teste2
/script/console.sh --newuser teste2
cp -a /script/auto.sh /home/teste2
chown teste2:teste2 /home/teste2/auto.sh
sed -i 's/\(export NODE_PORT=\).*/\13010/' /home/teste2/auto.sh

