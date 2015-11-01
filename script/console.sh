#!/bin/bash
set -x

# Scripts de configuração do Console
# A variável PS1 é configurada atravéz do srquivo $HOME/.bashrc
#   isso garante funcionamento igual em diversas Distros, testado com CentOS e Debian/Ubuntu
# sites:
#   http://unix.stackexchange.com/questions/70996/highlighting-command-in-terminal
#   http://www.thegeekstuff.com/2008/09/bash-shell-ps1-10-examples-to-make-your-linux-prompt-like-angelina-jolie/

# Chamada:
#   /script/network.sh --first          # Para primeira configuração, atualuza só root
#   /script/network.sh --newuser user   # logo dempois de criar um usuário

# Guarda parametros
CMD=$1
USR=$2
# usa as variaveis armazenadas
. /script/info/distro.var

#-----------------------------------------------------------------------
#--- Função para alterar arquivos: Cores
# uso: AddColorToFile <aqruivo>
# root usa LR+VM, usuário usa VD+VD
# Existe um problema com o whiptail de deixar os caracteres invisíveis...
#   infelizmente não me lembro como reproduz o problema.
#   Esta é a segunda correção, testaura a cor antes de voltar ao default, parece ok
function AddColorToFile(){
  local ARQ=$1
  # Precisa usar echo com Aspas simples para evitar expansão da expressão
  if ! grep "{NFAS-prompt}" $ARQ; then
    echo ''                                                                >> $ARQ
    echo '#{NFAS-prompt} configurado automáticamente: Prompt colorido'     >> $ARQ
    echo '# contribuição Marcos Carlos, quem desenvolveu estas cores...'   >> $ARQ
    # Quando o GIT usa o SSH usa terminal tipo "dumb" que não aceita comando tput
    #   e as mensagens de erro atrapalham o protocolo do git
    echo 'if [ "$TERM" != "dumb" ]; then'                                  >> $ARQ
    if [ "$ARQ" == "/root/.bashrc" ]; then
      echo '  export PS1="\[$(tput bold)\]\[$(tput setaf 3)\][\[$(tput setaf 1)\]\u\[$(tput setaf 3)\]@\[$(tput setaf 1)\]\h \[$(tput setaf 3)\]\W\[$(tput setaf 3)\]]\[$(tput setaf 1)\]\\$ \[$(tput setaf 7)\]\[$(tput sgr0)\]"' >> $ARQ
    else
      echo '  export PS1="\[$(tput bold)\]\[$(tput setaf 2)\][\[$(tput setaf 4)\]\u\[$(tput setaf 2)\]@\[$(tput setaf 4)\]\h \[$(tput setaf 2)\]\W\[$(tput setaf 2)\]]\[$(tput setaf 2)\]\\$ \[$(tput setaf 7)\]\[$(tput sgr0)\]"' >> $ARQ
    fi
    echo 'fi'                                                              >> $ARQ
    echo ''                                                                >> $ARQ
  fi
  # Esta versão também resolve eliminando as mensagens de erro (para usuário)
  # PS1="\[$(tput bold 2>/dev/null)\]\[$(tput setaf 2 2>/dev/null)\][\[$(tput setaf 4 2>/dev/null)\]"
  # PS1+="\u\[$(tput setaf 2 2>/dev/null)\]@\[$(tput setaf 4 2>/dev/null)\]\h \[$(tput setaf 2 2>/dev/null)\]"
  # PS1+="\W\[$(tput setaf 2 2>/dev/null)\]]\[$(tput setaf 2 2>/dev/null)\]\\$ \[$(tput sgr0 2>/dev/null)\]"
  # PS1+="\[$(tput setaf 7 2>/dev/null)\]"
  # export PS1
}

#-----------------------------------------------------------------------
#--- Função para alterar arquivos: umask
# uso: AddUmaskToFile <aqruivo>
# Altera UMASK para o bash, senão sobrepõe o configurado no PAM.D
# Alterando o .bashrc funciona  tanto no CentOS quanto no Ubuntu
function AddUmaskToFile(){
  local ARQ=$1
  # Evita repetir a alteração
  if ! grep "{NFAS-bash.umask}" $ARQ; then
    echo -e "\n#{NFAS-bash.umask} Configura máscara para criação de arquivos sem acesso a \"outros\"" >> $ARQ
    echo "umask 007" >> $ARQ
  fi
}

#-----------------------------------------------------------------------
# Altera Prompt para colorido:
#   Vermelho/Amarelo para root, Verde/Azul para usuário
if [ "$CMD" == "--first" ]; then
  # Altera o .bashrc do root, apenas uma vez
  AddUmaskToFile /root/.bashrc
  AddColorToFile /root/.bashrc
fi

#-----------------------------------------------------------------------
# Altera ao criar usuário
#   Vermelho/Amarelo para root, Verde/Azul para usuário
if [ "$CMD" == "--newuser" ] && [ -n "$USR" ]; then
  # Altera o .bashrc de cada usuário, sempre quando ele é criado
  AddUmaskToFile /home/$USR/.bashrc
  AddColorToFile /home/$USR/.bashrc
fi

