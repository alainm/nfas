#!/bin/bash
set -x

# Scripts de configuração do Console
# site: http://unix.stackexchange.com/questions/70996/highlighting-command-in-terminal
#       http://www.thegeekstuff.com/2008/09/bash-shell-ps1-10-examples-to-make-your-linux-prompt-like-angelina-jolie/
# Chamada:
#   /script/network.sh --first          # Para primeira configuração
#   /script/network.sh --newuser user   # when a new user was created

# Guarda parametros
CMD=$1
USR=$2
# usa as variaveis armazenadas
. /script/info/distro.var

#--- Função para alterar arquivos
# uso: AddColorToFile <aqruivo>
function AddColorToFile(){
  # Precisa usar echo com Aspas simples para evitar expansão da expressão
  echo ''                                                                >> $1
  echo '# NFAS: configurado automáticamente: Prompt colorido'            >> $1
  echo '# contribuição Marcos Carlos, quem desenvolveu estas cores...'   >> $1
  echo 'if [ $(id -u) -eq 0 ]; then'                                     >> $1
  echo '  export PS1="\[$(tput bold)\]\[$(tput setaf 3)\][\[$(tput setaf 1)\]\u\[$(tput setaf 3)\]@\[$(tput setaf 1)\]\h \[$(tput setaf 3)\]\W\[$(tput setaf 3)\]]\[$(tput setaf 1)\]\\$ \[$(tput sgr0)\]"' >> $1
  echo 'else'                                                            >> $1
  echo '  export PS1="\[$(tput bold)\]\[$(tput setaf 2)\][\[$(tput setaf 4)\]\u\[$(tput setaf 2)\]@\[$(tput setaf 4)\]\h \[$(tput setaf 2)\]\W\[$(tput setaf 2)\]]\[$(tput setaf 2)\]\\$ \[$(tput sgr0)\]"' >> $1
  echo 'fi'                                                              >> $1
  echo ''                                                                >> $1
}

# Altera Prompt para colorido:
#   Vermelho/Amarelo para root
#   Verde/Azul para usuário
if [ "$CMD" == "--first" ]; then
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    # No CentOS basta alterar o /etc/bashrc
    AddColorToFile /etc/bashrc
  elif  [ "$DISTRO_NAME" == "Ubuntu" ]; then
    # No Ubuntu tem que alterar cada $HOME/.bashrc, aqui altera apenas o
    AddColorToFile /root/.bashrc
  fi
fi

# Altera ao criar usuário
if [ "$CMD" == "--newuser" ]      && \
   [ "$DISTRO_NAME" == "Ubuntu" ] && \
   [ -n "$USR"];                      then
  # No Ubuntu tem que alterar cada $HOME/.bashrc, aqui altera apenas o
  AddColorToFile /home/$USR/.bashrc
fi

