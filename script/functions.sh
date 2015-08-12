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
# Formato dos parametros: "param:  valor" de separador é ":"
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
# Função para ler Arquivo de configuração, parametro separado por " "
# Formato dos parametros: "param  valor" de separador é " "
# uso: EditConfColon <Arquivo> <param>
function GetConfSpace(){
  local ARQ=$1
  local PARAM=$2
  # Le vaiável direto do arquivo
  local TMP=$(eval "sed -n 's/^[[:blank:]]*"$PARAM"[[:blank:]]\+\(.*\)[[:blank:]]*$/\1/p'" $ARQ)
  if [ -z "$TMP" ]; then
    # Tenta ler em comentários, geralmente é o default
    TMP=$(eval "sed -n 's/^[[:blank:]]*#\?[[:blank:]]*"$PARAM"[[:blank:]]\+\(.*\)[[:blank:]]*$/\1/p'" $ARQ)
  fi
  echo $TMP
}

#-----------------------------------------------------------------------
# Função para editar Arquivo de configuração, parametro separado por " "
# Formato dos parametros: "param:  valor" de separador é " "
# uso: EditConfSpace <Arquivo> <param> <valor>
# usa método de substituir, CUIDADO com caracteres que podeminterferir com o SED
function EditConfSpace(){
  local ARQ=$1
  local PARAM=$2
  local VAL=$3
  if grep -E "^[[:blank:]]*$PARAM[[:blank:]]+" $ARQ; then
    # linha já existe, substituir no local
    # Cuidado no grep é "+" e no sed é "\+"
    eval "sed -i 's/^\([[:blank:]]*$PARAM[[:blank:]]\+\).*/\1$VAL/;' $ARQ"
   elif grep -E "^[[:blank:]]*#*[[:blank:]]*$PARAM[[:blank:]]+" $ARQ; then
    # linha já existe, substituir no local, Retirar comentário
    eval "sed -i 's/^[[:blank:]]*#\?\([[:blank:]]*$PARAM[[:blank:]]\+\).*/\1$VAL/;' $ARQ"
  else
    # linha com parametro não existe, acrescenta linha no final
    echo "$PARAM   $VAL" >> $ARQ
  fi
}

#-----------------------------------------------------------------------
# Importa uma PublicKey
# Uso: AskNewKey usuario diretorio
function AskNewKey(){
  local TMP, MSG, OLD_N
  local USR=$1
  local DIR=$2
  # loop só sai com return
  while true; do
       MSG="\nForneca o Certificado Chave Pública (PublicKey) para acesso como \"$USR\""
      MSG+="\n (deixe em branco se não pretende usar)"
    MSG+="\n\nUse estes comandos no Linux para gerar as chaves com identificação"
      MSG+="\n(Linha muito longa, copiar com <Ctrl+Shift+C> em duas vezes)"
    MSG+="\n\n   ssh-keygen -t rsa -b 4096 -f ~/.ssh/$USR@$(hostname).key"
      MSG+="\n         -C \"\$USER@\$(hostname).key.pub\""
    MSG+="\n\nComando para mostrar na tela e poder copiar:"
      MSG+="\n   cat ~/.ssh/$USR@$(hostname).key.pub"
    MSG+="\n"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    TMP=$(whiptail --title "Chave Pública do usuário $USR" --inputbox "$MSG" 20 78 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ] || [ -z "$TMP" ]; then
      echo "Operação cancelada!"
      return 1
    else
      # Cria diretório caso não exista
      mkdir -p $DIR/.ssh/; chmod 700 $DIR/.ssh/
      if [ "$DISTRO_NAME" == "CentOS" ]; then
        ## >>CentOS<<: http://wiki.centos.org/HowTos/Network/SecuringSSH
        # Ensure the correct SELinux contexts are set:
        restorecon -Rv $DIR/.ssh
      fi
      # Testa se já existe uma PublicKey com essa identificação
sed -n 's/^[[:blank:]]*$PARAM[[:blank:]]* \(.*\)[[:blank:]]*$/\1/p'      if [ $OLD_N -ne 0 ]; then
        MSG="Já exisste uma Chave Pública (PublicKey) com esta identificação"
        MSG+="\n\n Deseja mesmo SUBSTITUÍ-LA?"
        if ( ! whiptail --title "Chave Pública do usuário $USR" --yesno "$MSG" 10 78) then
          continue
        fi
      fi
      # Elimina entradas com mesma identificação
      eval "sed -i '/"$(echo -n $TMP | cut -d' ' -f3)"/d' $DIR/.ssh/authorized_keys"
      # Acrescenta a nova publickey
      echo -e "\n$TMP" >> $DIR/.ssh/authorized_keys
      # Tem que ter permissões bloqueadas
      chmod 600 $DIR/.ssh/authorized_keys
      # Elimina linhas em branco
      sed -i '/^$/d' $DIR/.ssh/authorized_keys
      # Mensagem de confirmação
      if [ $OLD_N -eq 0 ]; then
        MSG="\nA sua Chave Pública (PublicKey) foi acrescentada para acesso seguro."
      else
        MSG="\nA sua Chave Pública (PublicKey) foi substituida para acesso seguro."
      fi
      MSG+="\nO seu comando para acessar este servidor por SSH é:"
      MSG+="\n\n   ssh -i ~/.ssh/$USR@$(hostname).key $USR@$(ifconfig eth0 | GetIpFromIfconfig)"
      MSG+="\n\n==>> ANOTE este comando <<=="
      MSG+="\nRecomendamos que teste agora..."
      MSG+="\n\nOK? SIM para continuar, NÃO para repetir operação"
      if (whiptail --title "Chave Pública do usuário $USR" --yesno "$MSG" 17 78) then
        echo "Chave Pública cadastrada com sucesso"
        return 0
      fi
    fi
  done
}

#-----------------------------------------------------------------------
# Importa PublicKeys existentes
# Uso: DeleteKeys usuario diretorio
function DeleteKeys(){
  local I, LIN, MSG, AMSG, EXE, KEYS
  local USR=$1
  local DIR=$2
  local TITLE="NFAS - Removendo Chaves Públicas do usuário $USR"
    # Elimina linhas em branco
    sed -i '/^$/d' $DIR/.ssh/authorized_keys
    # Lista as chaves existentes e coloca numa array
    I=0
    while read LIN ; do
      AMSG[$I]=$(echo $LIN | cut -d' ' -f3)
      let I=I+1
    done < $DIR/.ssh/authorized_keys
    N_LIN=${#AMSG[*]} # Número de linhas
    if [ "$N_LIN" == "0" ]; then
      # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
      whiptail --title "$TITLE" --msgbox "Não foi encontrada nenhuma Chave Pública para o usuário $USR.\n\nOK para continuar" 10 70
      return 0
    fi
    EXE="whiptail --title \"$TITLE\""
    EXE+=" --checklist \"\nSelecione as Chaves Públicas que deseja remover\" 22 75 $N_LIN"
    for ((I=0; I<N_LIN; I++)); do
      # Cria as mensagens para seleção das chaves que pretende remover
      EXE+=" \"${AMSG[$I]}\" \"\" OFF"
    done
    KEYS=$(eval "$EXE 3>&1 1>&2 2>&3")
    [ $? != 0 ] && return 0 # Cancelado
    # Remove as chaves selecionadas
    for K in $(echo $KEYS | tr -d '\"'); do
      echo "Removendo chave: $K"
      eval "sed -i '/"$K"/d' $DIR/.ssh/authorized_keys"
    done
}

#-----------------------------------------------------------------------
