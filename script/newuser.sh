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

#-----------------------------------------------------------------------
# Função para perguntar e verificar nome da aplicação/usuário
# uso: AskName "Tipo de nome"
# NOME é para mostrar na tela
# Retorna: 0=ok, 1=Aborta se <Cancelar>
function AskName(){
  local SHOW=$1
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
      ABORT="Y"
      return 1
    fi
    # Validação do nome
    # Site ajudou: http://www.regular-expressions.info/email.html
    LC_CTYPE="C"
    # Testa se só tem caracteres válidos
    NAME_TMP=$(echo $TMP | grep -E '^[a-zA-Z0-9]+$')
    # Testa combinações inválidas
    if [ "$NAME_TMP" != "" ] &&        # testa se vazio, pode ter sido recusado pela ER...
       [ "$NAME_TMP" == "$TMP" ]; then # Não foi alterado pela ER
      # Email aceito, Continua
      echo "$TMP"
      return 0
    else
      ERR_ST="Nome inválido, por favor tente novamente"
    fi
  done

}

#-----------------------------------------------------------------------
# Rotina para Criar uma Aplicação (usuário Linux)
function NewApp(){
  local NEW_NAME=$(AskName "Nome da Aplicação")
  [ $? != 0 ] && echo "Nome Cancelado"; exit 1
  echo "Nova Aplicação: $NEW_NAME"
}

#-----------------------------------------------------------------------
# main()

TITLE="NFAS - Configuração de Aplicações e Usuários"
if [ "$CMD" == "--first" ]; then
  NewApp


#-----------------------------------------------------------------------
else [ "$CMD" == "--email" ]; then
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

