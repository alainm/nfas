#!/bin/bash
# set -x

# Scripts de configuração do Console
# A variável PS1 é configurada atravéz do srquivo $HOME/.bashrc
#   isso garante funcionamento igual em diversas Distros, testado com CentOS e Debian/Ubuntu
# sites:
#   http://unix.stackexchange.com/questions/70996/highlighting-command-in-terminal
#   http://www.thegeekstuff.com/2008/09/bash-shell-ps1-10-examples-to-make-your-linux-prompt-like-angelina-jolie/

# Chamada:
#   /script/console.sh --first          # Para primeira configuração, atualuza só root
#   /script/console.sh --newuser user   # logo dempois de criar um usuário
#   /script/console.sh --wellcome       # quando faz login pelo ssh (no .bashrc)

# Guarda parametros
CMD=$1
USR=$2
# usa as variaveis armazenadas
. /script/info/distro.var
. /script/info/state.var
[ -e /script/info/network.var ] && . /script/info/network.var
# Funções auxiliares
. /script/functions.sh

#-----------------------------------------------------------------------
# Configura /etc/sudoers para mensagem de login
# precisa de acesso sudo para ler o log e envirmment para SSH
function SetSudoersWelcome(){
  local ARQ=/etc/sudoers
  # faz uma cópia do original e protege contra olhares alheios
  if [ ! -e $ARQ.orig ]; then
    cp -a $ARQ $ARQ.orig
    chmod 440 $ARQ.orig
  fi
  # Só insere comando uma única vez
  if ! grep "{NFAS-wellcome}" $ARQ >/dev/null; then
    echo -e '\n#{NFAS-wellcome} configurado automáticamente: Mensagem de Segurança/Boas vindas' >> $ARQ
    echo -e '# Permite acesso a qualquer usuário, apenas ao comando e parametro específico'   >> $ARQ
    echo -e 'ALL ALL=NOPASSWD:SETENV: /script/console.sh --wellcome\n'                          >> $ARQ
  fi
}

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
  if ! grep "{NFAS-prompt}" $ARQ >/dev/null; then
    echo ''                                                                               >> $ARQ
    echo '#{NFAS-prompt} configurado automáticamente: Prompt colorido'                    >> $ARQ
    # Quando o GIT usa o SSH usa terminal tipo "dumb" que não aceita comando tput
    #   e as mensagens de erro atrapalham o protocolo do git
    echo 'if [ "$TERM" == "dumb" ]; then'                                                 >> $ARQ
    echo '  # Retorna se é SFTP ou SCP, só pode escrever na tela se for SSH'              >> $ARQ
    echo '  return 0'                                                                     >> $ARQ
    echo 'fi'                                                                             >> $ARQ
    # Force en_US.UTF-8, nome scripts may be sensitive to translation
    echo 'export LANG=en_US.UTF-8'                                                        >> $ARQ
    echo '# Cores do Prompt, contribuição Marcos Carlos, quem desenvolveu estas cores...' >> $ARQ
    if [ "$ARQ" == "/root/.bashrc" ]; then
      echo 'export PS1="\[$(tput bold)\]\[$(tput setaf 3)\][\[$(tput setaf 1)\]\u\[$(tput setaf 3)\]@\[$(tput setaf 1)\]\h \[$(tput setaf 3)\]\W\[$(tput setaf 3)\]]\[$(tput setaf 1)\]\\$ \[$(tput setaf 7)\]\[$(tput sgr0)\]"' >> $ARQ
      echo '# Mensagem de segurança e boas vindas'                                        >> $ARQ
      echo '/script/console.sh --wellcome'                                                >> $ARQ
    else
      echo 'export PS1="\[$(tput bold)\]\[$(tput setaf 2)\][\[$(tput setaf 4)\]\u\[$(tput setaf 2)\]@\[$(tput setaf 4)\]\h \[$(tput setaf 2)\]\W\[$(tput setaf 2)\]]\[$(tput setaf 2)\]\\$ \[$(tput setaf 7)\]\[$(tput sgr0)\]"' >> $ARQ
      echo 'if [ -n "$SSH_TTY" ]; then'                                                   >> $ARQ
      echo '  # Só executa se login pelo SSH'                                             >> $ARQ
      echo '  /script/console.sh --wellcome'                                              >> $ARQ
      # Eliminado, gera lixo em scripts
      # echo 'else'                                                                       >> $ARQ
      # echo '  echo -e "\n Acesso seguro via CONSOLE! Bemvindo ao \"$(hostname)\"\n"'    >> $ARQ
      echo 'fi'                                                                           >> $ARQ
      echo '# muda para diretório do usuário, caso usem "su user"'                        >> $ARQ
      echo '[ $(id -u) -ne 0 ] && cd'                                                     >> $ARQ
    fi
    echo ''                                                                               >> $ARQ
  fi
}

#-----------------------------------------------------------------------
#--- Função para alterar arquivos: umask
# uso: AddUmaskToFile <aqruivo>
# Altera UMASK para o bash, senão sobrepõe o configurado no PAM.D
# Também altera permissões de /dev/pts/* para usar screen
# Alterando o .bashrc funciona  tanto no CentOS quanto no Ubuntu
function AddUmaskToFile(){
  local ARQ=$1
  # Evita repetir a alteração
  if ! grep "{NFAS-bash.umask}" $ARQ >/dev/null; then
    echo -e "\n#{NFAS-bash.umask} Configura máscara para criação de arquivos sem acesso a \"outros\"" >> $ARQ
    echo "umask 007" >> $ARQ
  fi
}

#-----------------------------------------------------------------------
# Escreve mensagem inicial de segurança e/ou boas vindas
function SayWellcome(){
  # Como root a mensagem é diferente
  if [ "$(id -u)" == "0" ]; then
    # Le o tipo de Login: password ou publickey
    local LOGIN_TYPE=$(GetLoginType)
    # Lê se acesso por Senha é permitido: yes ou no
    local PASS_AUTH=$(GetConfSpace /etc/ssh/sshd_config PasswordAuthentication)
    if [ "$LOGIN_TYPE" == "password" ]; then
      # Acesso foi inseguro usando senha
      echo -e "\n         ┌──────────────────────────────────────┐"
      echo -e   "         │     Esta Conexão não é SEGURA ...    │"
      echo -e   "         └──────────────────────────────────────┘"
      echo -e "Seu login foi feito com SENHA"
      echo -e "Cadastre uma chave pública para acesso e comece a usá-la."
      echo -e "Utilize o comando nfas (como root) para fazê-lo.\n"
    elif [ "$LOGIN_TYPE" == "publickey" ]; then
      if [ "$PASS_AUTH" == "yes" ]; then
        # Acesso foi seguro usando PublicKey mas senha está habilitada
        echo -e "\n         ┌──────────────────────────────────────┐"
        echo -e   "         │     Esta Conexão não é SEGURA ...    │"
        echo -e   "         └──────────────────────────────────────┘"
        echo -e "Você usou uma Chave Pública, mas o acesso por SENHA está habilitado!!!"
        echo -e "Utilize o comando nfas (como root) para deshabilitar acesso por SENHA.\n"
      else
        # Acesso com PublicKey ok
        echo -e "\n Acesso seguro por Chave Pública!"
        echo -e "\n Bemvindo ao \"$(hostname)\"\n"
      fi
    # Eliminado, gera lixo em scripts
    # else
    #   echo "ERRO: Log desta conexão não encontrado"
    fi
  else
    if [ "$SST_SSH_PASS_AUTH" == "yes" ]; then
      # Acesso foi seguro usando PublicKey mas senha está habilitada
      echo -e "\n         ┌──────────────────────────────────────┐"
      echo -e   "         │     Esta Conexão não é SEGURA ...    │"
      echo -e   "         └──────────────────────────────────────┘"
      echo -e   "O acesso por SENHA está habilitado!!!"
      echo -e   "Utilize o comando nfas (como root) para deshabilitar acesso por SENHA.\n"
    else
      # Acesso com PublicKey ok
      echo -e "\n Acesso seguro por Chave Pública!"
      echo -e "\n Bemvindo ao \"$(hostname)\"\n"
      fi
  fi
}
#=======================================================================
# Altera Prompt para colorido:
#   Vermelho/Amarelo para root, Verde/Azul para usuário
if [ "$CMD" == "--first" ]; then
  # Libera acessos necessários para mensagem de Segurança / Boas vindas
  SetSudoersWelcome
  # Altera o .bashrc do root, apenas uma vez
  AddUmaskToFile /root/.bashrc
  AddColorToFile /root/.bashrc

#-----------------------------------------------------------------------
elif [ "$CMD" == "--wellcome" ]; then
  # Mensagem inicial
  SayWellcome
  if [ "$NEW_IP_CONTINUE" == "Y" ] && [ -n "$SSH_TTY" ]; then
    /script/first.sh --ip-continue
  fi
fi

#-----------------------------------------------------------------------
# Altera ao criar usuário
#   Vermelho/Amarelo para root, Verde/Azul para usuário
if [ "$CMD" == "--newuser" ] && [ -n "$USR" ]; then
  # Altera o .bashrc de cada usuário, sempre quando ele é criado
  AddUmaskToFile /home/$USR/.bashrc
  AddColorToFile /home/$USR/.bashrc
fi

