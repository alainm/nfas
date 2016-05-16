#!/bin/bash
set -x

# Script para criar um novo usuário
# Uso: /script/newuser.sh
# <cmd>: --first       primeira instalação
#        --newapp      cria nova aplicação
#        --chgapp      altera acesso da aplicação
#        <em branco>   modo interativo, não usado

#=======================================================================
# Processa a linha de comando
CMD=$1
# Funções auxiliares
. /script/functions.sh
. /script/info/distro.var
# variaveis globais
APP_NAME=""
REPO_DIR=""
# Comando de execução do SU é diferente em cada distro
[ "$DISTRO_NAME" == "CentOS" ] && SU_C="--session-command" || SU_C="-c"

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
    MSG="\n\nQual o $SHOW (deve ser válido como usuário Linux)?\n"
    # if [ -n "$TMP" ]; then
    #   MSG+="\n<Enter> para manter o anterior sendo mostrado"
    # else
    #   MSG+="\n"
    # fi
    # Acrescenta mensagem de erro
    MSG+="\n\n$ERR_ST\n"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    TMP=$(whiptail --title "$TITLE" --inputbox "$MSG" 14 74 $TMP 3>&1 1>&2 2>&3)
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
      # Nome válido, testa se já existe user
      id $NAME_TMP
      if [ $? -eq 0 ]; then
        ERR_ST="Já existe um usuário Linux com este nome, por favor tente novamente"
      else
        # testa també se já existe grupo com esse nome
        egrep -i "^$NAME_TMP" /etc/group
        if [ $? -eq 0 ]; then
          ERR_ST="Já existe um grupo Linux com este nome, por favor tente novamente"
        else
          eval "$VAR=$TMP"
          return 0
        fi
      fi
    else
      ERR_ST="Nome inválido, por favor tente novamente"
    fi
  done

}

#-----------------------------------------------------------------------
# Função para perguntar e verificar uma Senha
# uso: AskPasswd <VAR> "Tipo de senha"
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
    MSG="\nQual a senha de $SHOW"
    MSG+="\n\nCaracteres válidos: a-zA-Z0-9!@#$%^&*()_-+={};:,./?"
    MSG+="\n  (use senha segura...)"
    # Acrescenta mensagem de erro
    MSG+="\n\n$ERR_ST"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    PWD1=$(whiptail --passwordbox --title "$TITLE"  "$MSG" 14 74 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operação cancelada!"
      return 1
    fi
    MSG="\n\nDigite novamente a senha para verificação\n\n\n\n"
    PWD2=$(whiptail --passwordbox --title "$TITLE"  "$MSG" 14 74 3>&1 1>&2 2>&3)
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
  local NEW_PWD
  # APP_NAME é global
  AskName APP_NAME "Nome da Aplicação"
  [ $? != 0 ] && return 1
  AskPasswd NEW_PWD "Senha do usuário \"$APP_NAME\""
  [ $? != 0 ] && return 1
  echo "Nova Aplicação: $APP_NAME, passwd: $NEW_PWD"
  # criando usuários
  # OBS: useradd não cria o home directory no Ubuntu 14.04, só com "-m"
  useradd -m $APP_NAME
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    echo "$NEW_PWD" | passwd --stdin $APP_NAME
  else
    # OBS: --stdin só funciona no CentOS (não no Ubuntu 14.04)
    # http://ccm.net/faq/790-changing-password-via-a-script
    # echo "$NEW_PWD" | passwd --stdin $APP_NAME
    echo "Ubuntu..."
  fi
  # outros scripts que precisam reconfigurar
  /script/console.sh --newuser $APP_NAME
  /script/postfix.sh --newuser $APP_NAME
  # Script de inicialização
  mkdir /home/$APP_NAME/app
  cp -a /script/auto.sh /home/$APP_NAME
  cp -a /script/server.js /home/$APP_NAME/app
  chown -R $APP_NAME:$APP_NAME /home/$APP_NAME
  return 0
}

#-----------------------------------------------------------------------
# Tela de seleção das Aplicações
# usa como referências os diretórios em /home
function SelectApp(){
  local AUSR
  local USR
  local NUSR
  local KEYS
  APP_NAME="" # limpa variável de saída
  # cria Array de usuários existentes
  I=0
  for USR in $(ls /home) ; do
    id $USR
    if [ $? -eq 0 ]; then
      echo "Usuário encontrado: $USR"
      AUSR[$I]=$USR
      let I=I+1
    fi
  done
  NUSR=${#AUSR[*]} # Número de linhas
  if [ "$NUSR" == "0" ]; then
    whiptail --title "$TITLE" --msgbox "Não foi encontrado nenhum Aplicação/Usuário.\n\nOK para continuar" 10 70
    return 1
  fi
  # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
  EXE="whiptail --title \"$TITLE\""
  EXE+=" --menu \"\nSelecione a Aplicação/Usuário que deseja configurar\" 20 60 $NUSR"
  for ((I=0; I<NUSR; I++)); do
    # Cria as mensagens para seleção da aplicação
    EXE+=" \"${AUSR[$I]}\" \"\""
  done
  KEYS=$(eval "$EXE 3>&1 1>&2 2>&3")
  [ $? != 0 ] && return 2 # Cancelado
  APP_NAME=$KEYS
  echo "Aplicação selecionada: $APP_NAME"
}

#-----------------------------------------------------------------------
# Pergunta nome do diretório GIT
# uso: AskRepoName <VAR> Aplicação
# VAR é a variável que vai receber a resposta
function AskRepoName(){
  local VAR=$1
  local USR=$2
  local TMP
  local DIR_TMP
  while true; do
     MSG="\nQual o diretório para o repositório a ser criado?"
    MSG+="\n  (será criado o diretório dentro de /home/$USR)\n"
    MSG+="\n\n$ERR_ST\n"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    TMP=$(whiptail --title "$TITLE" --inputbox "$MSG" 14 74 $TMP 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operação cancelada!"
      return 1
    fi
    # Testa se só tem caracteres válidos
    # http://serverfault.com/questions/73084/what-characters-should-i-use-or-not-use-in-usernames-on-linux
    REPO_TMP=$(echo $TMP | grep -E '^[a-zA-Z0-9_][a-zA-Z0-9_-.]*[a-zA-Z0-9_]$')
    # Testa combinações inválidas
    if [ "$REPO_TMP" != "" ] &&        # testa se vazio, pode ter sido recusado pela ER...
       [ "$REPO_TMP" == "$TMP" ]; then # Não foi alterado pela ER
      # Nome válido, verifica se já existe este nome
      ls /home/$USR/$REPO_TMP  &> /dev/null
      if [ $? -eq 0 ]; then
        # Nome para diretório está em uso
        ERR_ST="Este nome já está em uso, por favor tente novamente"
      else
        eval "$VAR=/home/$USR/$REPO_TMP"
        return 0
      fi
    else
      ERR_ST="Nome inválido, por favor tente novamente"
    fi
  done
}

#-----------------------------------------------------------------------
# Cria Repositório GIT
# uso: CreateRepo <user>
function CreateRepo(){
  local USR=$1
  # Le o nome do diretório e já testa se existe
  AskRepoName REPO_DIR $USR
  # Cria diretório do repositório, tem que criar como usuário
  su $USR -l -c "mkdir -p $REPO_DIR"

}
#-----------------------------------------------------------------------
# Submenu para configurar acessos à Aplicação
# Entrada variável global: APP_NAME
function ConfigApp(){
  local MENU_IT
  local MSG9
  while true; do
    # na primeira vez tem uma opção "Continuar.." para melhor compreensão
    if [ "$CMD" == "--first" ]; then
      MENU_IT=$(whiptail --title "$TITLE" \
        --menu "\nComando de reconfiguração, aplicação: \"$APP_NAME\"" --fb 18 70 5   \
        "1" "Configurar HTTP(S) e URL/URIs de acesso"\
        "2" "Acrescentar Chave Pública (PublicKey)"  \
        "3" "Remover Chave Pública (PublicKey)"      \
        "4" "Criar Repositório GIT"                  \
        "9" "Continuar..."                           \
        3>&1 1>&2 2>&3)
    else
      MENU_IT=$(whiptail --title "$TITLE" --cancel-button "Retornar" \
        --menu "\nComando de reconfiguração, aplicação: \"$APP_NAME\"" --fb 18 70 4   \
        "1" "Configurar HTTP(S) e URL/URIs de acesso"    \
        "2" "Acrescentar Chave Pública (PublicKey)"  \
        "3" "Remover Chave Pública (PublicKey)"      \
        "4" "Criar Repositório GIT"                  \
        3>&1 1>&2 2>&3)
    fi
    [ $? != 0 ] && return 0 # Cancelado
    [ "$MENU_IT" == "9" ] && return 0 # Fim
    # Funções que ficam em Procedures
    #  Configura URIs
    [ "$MENU_IT" == "1" ] && /script/haproxy.sh --app $APP_NAME
    # Novo certificado de acesso
    [ "$MENU_IT" == "2" ] && AskNewKey $APP_NAME /home/$APP_NAME
    # Remove certificado de root
    [ "$MENU_IT" == "3" ] && DeleteKeys $APP_NAME /home/$APP_NAME
    # Cria Repositório GIR
    [ "$MENU_IT" == "4" ] && CreateRepo $APP_NAME
  done
}

#-----------------------------------------------------------------------
# main()

TITLE="NFAS - Configuração de Aplicações e Usuários"
if [ "$CMD" == "--first" ]; then
  NewApp
  if [ $? == 0 ]; then
    AskNewKey $APP_NAME /home/$APP_NAME
    /script/haproxy.sh --app $APP_NAME
    # Inicia App com exemplo padrão, facilita os teste, mesmo se vai rebootar
    su - $APP_NAME $SU_C "nohup /home/$APP_NAME/auto.sh </dev/null 2>&1 >/dev/null &"
  fi

#-----------------------------------------------------------------------
elif [ "$CMD" == "--newapp" ]; then
  # Chamado pelo menu do nfas.sh
  NewApp
  if [ $? == 0 ]; then
    AskNewKey $APP_NAME /home/$APP_NAME
    /script/haproxy.sh --app $APP_NAME
    # Inicia App com exemplo padrão
    su - $APP_NAME $SU_C "nohup /home/$APP_NAME/auto.sh </dev/null 2>&1 >/dev/null &"
  fi

#-----------------------------------------------------------------------
elif [ "$CMD" == "--chgapp" ]; then
  # Chamado pelo menu do nfas.sh
  SelectApp
  if [ $? == 0 ]; then
    ConfigApp $APP_NAME
  fi

#-----------------------------------------------------------------------
else
  # Loop do Menu principal interativo
  # (não é chamadao pelo nfas.sh, ficou sem uso)
  while true; do
    MENU_IT=$(whiptail --title "NFAS - Node.js Full Application Server" \
        --menu "Selecione um comando de reconfiguração:" --fb 18 70 2   \
        "1" "Criar nova Aplicação (usuário Linux)"  \
        "2" "Configurar acesso WEB à Aplicação" \
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
