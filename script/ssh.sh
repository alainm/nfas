
#!/bin/bash
set -x

# Script para Configurar SSH e acesso de ROOT
# As perguntas são interativas através de TUI
# Uso: /script/ssh.sh <cmd>
# <cmd>: --first     primeira instalação, não mosta menu
#        <em branco> Mostra menu interativo
#
# * acrescentar certificado publickey (--first)
# * eliminar certificado publickey
# * bloquear acesso de root pelo ssh (--first)
# * bloquear acesso pelo ssh com senha (--first)
# * alterar senha de root
# * (re)configurar portknock (--first)

#-----------------------------------------------------------------------
# Grava Variáveis de configuração
function SaveVars(){
  echo "SSH_=\"$SSH_\""                        2>/dev/null >  $VAR_FILE
  echo "SSH_=\"$SSH_\""                        2>/dev/null >> $VAR_FILE
}

#-----------------------------------------------------------------------
# Importa uma PublicKey
function AskKey(){
  local TMP, MSG, OLD_N
  # loop só sai com return
  while true; do
       MSG="\nForneca o Certificado Chave Pública (PublicKey) para acesso como ROOT"
      MSG+="\n (deixe em branco se não pretende usar)"
    MSG+="\n\nUse estes comandos no Linux para gerar as chaves com identificação"
      MSG+="\n(Linha muito longa, copiar com <Ctrl+Shift+C> em duas vezes)"
    MSG+="\n\n   ssh-keygen -t rsa -b 4096 -f ~/.ssh/root@$(hostname).key"
      MSG+="\n         -C \"\$USER@\$(hostname).key.pub\""
    MSG+="\n\nComando para mostrar na tela e poder copiar:"
      MSG+="\n   cat ~/.ssh/root@$(hostname).key.pub"
    MSG+="\n"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    TMP=$(whiptail --title "Chave Pública de root" --inputbox "$MSG" 20 78 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ] || [ -z "$TMP" ]; then
      echo "Operação cancelada!"
      return 1
    else
      # Cria diretório caso não exista
      mkdir -p /root/.ssh/; chmod 700 /root/.ssh/
      if [ "$DISTRO_NAME" == "CentOS" ]; then
        ## >>CentOS<<: http://wiki.centos.org/HowTos/Network/SecuringSSH
        # Ensure the correct SELinux contexts are set:
        restorecon -Rv /root/.ssh
      fi
      # Testa se já existe uma PublicKey com essa identificação
      OLD_N=$(eval "sed -n '/"$(echo -n $TMP | cut -d' ' -f3)"/p' /root/.ssh/authorized_keys | wc -l")
      if [ $OLD_N -ne 0 ]; then
        MSG="Já exisste uma Chave Pública (PublicKey) com esta identificação"
        MSG+="\n\n Deseja mesmo SUBSTITUÍ-LA?"
        if (whiptail --title "Chave Pública de root" --yesno "$MSG" 10 78) then
          # Elimina entradas com mesma identificação
          eval "sed -i '/"$(echo -n $TMP | cut -d' ' -f3)"/d' /root/.ssh/authorized_keys"
          # Acrescenta a nova publickey
          echo -e "\n$TMP" >> /root/.ssh/authorized_keys
          # Elimina linhas em branco
          sed -i '/^$/d' /root/.ssh/authorized_keys
          # Mensagem de confirmação
          if [ $OLD_N -eq 0 ]; then
            MSG="\nA sua Chave Pública (PublicKey) foi acrescentada para acesso seguro."
          else
            MSG="\nA sua Chave Pública (PublicKey) foi substituida para acesso seguro."
          fi
          MSG+="\nO seu comando para acessar este servidor por SSH é:"
          MSG+="\n\n   ssh -i ~/.ssh/root@$(hostname).key root@$(ifconfig eth0 | GetIpFromIfconfig)"
          MSG+="\n\n==>> ANOTE este comando <<=="
          MSG+="\nRecomendamos que teste agora..."
          MSG+="\n\n SIM para continuar, NÃO para repetir operação"
          if (whiptail --title "Chave Pública de root" --yesno "$MSG" 17 78) then
            echo "Chave Pública cadastrada com sucesso"
            return 0
          fi
        fi
      fi
    fi
  done
}

#=======================================================================
# Processa a linha de comando
CMD=$1
# Funções auxiliares
. /script/functions.sh
# Lê dados anteriores se existirem
. /script/info/distro.var
VAR_FILE="/script/info/h.var"
[ -e $VAR_FILE ] && . $VAR_FILE

#-----------------------------------------------------------------------
# main()

# somente root pode executar este script
if [ "$(id -u)" != "0" ]; then
  echo "Somente root pode executar este comando"
  exit 255
fi
if [ "$CMD" == "--first" ]; then
  # Durante instalação não mostra menus
  echo "1"

else
  # Loop do Monu principal interativo
  while true; do
    # Mostra Menu
    MSG_ROOT_SSH="Bloquear acesso de root pelo SSH,   ATUAL=permitido"
    MSG_SSH_SENHA="Bloquear acesso pelo SSH com senha, ATUAL=permitido"
    MENU_IT=$(whiptail --title "NFAS - Node.js Full Application Server" \
        --menu "Selecione um comando de reconfiguração:" --fb 18 70 6   \
        "1" "Acrescentar Certificado PublicKey"  \
        "2" "Remover Certificado PublicKey"      \
        "3" "$MSG_ROOT_SSH"                      \
        "4" "$MSG_SSH_SENHA"                     \
        "5" "Alterar senha de root"              \
        "6" "Reconfigurar PortKnock"             \
        3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
        echo "Seleção cancelada."
        exit 0
    fi
    # Todas as funções ficam em Procedures
    [ "$MENU_IT" == "1" ] && AskKey
    [ "$MENU_IT" == "2" ] && echo "Não implementado"
    [ "$MENU_IT" == "3" ] && echo "Não implementado"
    [ "$MENU_IT" == "4" ] && echo "Não implementado"
    [ "$MENU_IT" == "5" ] && echo "Não implementado"
    [ "$MENU_IT" == "6" ] && echo "Não implementado"
    # read -p "Enter para continuar..." TMP
  done # loop menu principal
fi # else --first

