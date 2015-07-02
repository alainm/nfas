#!/bin/bash
set -x

# Scripts de configuração do Console
# A variável PS1 é configurada atravéz do srquivo $HOME/.bashrc
#   isso garante funcionamento igual em diversas Distros, testado com CentOS e Debian/Ubuntu
# sites:
#   http://unix.stackexchange.com/questions/70996/highlighting-command-in-terminal
#   http://www.thegeekstuff.com/2008/09/bash-shell-ps1-10-examples-to-make-your-linux-prompt-like-angelina-jolie/

# Chamada:
#   /script/network.sh --first          # Para primeira configuração
#   /script/network.sh --newuser user   # logo dempois de criar um usuário

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

#-----------------------------------------------------------------------
# Altera Prompt para colorido:
#   Vermelho/Amarelo para root, Verde/Azul para usuário
if [ "$CMD" == "--first" ]; then
  # Altera o .bashrc do root, apenas uma vez
  AddColorToFile /root/.bashrc
fi

#-----------------------------------------------------------------------
# Altera ao criar usuário
#   Vermelho/Amarelo para root, Verde/Azul para usuário
if [ "$CMD" == "--newuser" ] && [ -n "$USR" ]; then
  # Altera o .bashrc de cada usuário, sempre quando ele é criado
  AddColorToFile /home/$USR/.bashrc
fi

