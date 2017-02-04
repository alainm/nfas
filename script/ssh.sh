#!/bin/bash
set -x

# Script para Configurar SSH e acesso de ROOT
# As perguntas são interativas através de TUI
# Uso: /script/ssh.sh <cmd>
# <cmd>: --first       primeira instalação, não mosta menu
#        --firewall    chamado durante o boot pelo 10-firewall.sh
#        --hostname    foi alerado o hostname (usado pelo fail2ban)
#        --email <user> Envia email com instruções de acesso
#        <em branco>   Mostra menu interativo
#
# * acrescentar certificado publickey (--first)
# * eliminar certificado publickey
# * bloquear acesso de root pelo ssh (--first)
# * bloquear acesso pelo ssh com senha (--first)
# * alterar senha de root
# * (re)configurar portknock (--first)

#=======================================================================
# Processa a linha de comando
CMD=$1
# Funções auxiliares
. /script/functions.sh
# Lê dados anteriores se existirem
. /script/info/distro.var
. /script/info/email.var
VAR_FILE="/script/info/ssh.var"
[ -e $VAR_FILE ] && . $VAR_FILE

#-----------------------------------------------------------------------
# get current SSHD version
function GetSshdVersion(){
  local PRG=$(which sshd)
  # sshd has no command line to show version, use an inocuous option and read the mini-help
  local VER=$($(which sshd)  -o 2>&1 | grep "OpenSSH_" | sed 's/OpenSSH_\([0-9]\+\.[0-9]\+\).*/\1/;')
  echo $VER
}

#-----------------------------------------------------------------------
# Test SSH version
# usage TestSshVersion <min>
# retuns true if current version is >= to given <min>
function TestSshdVersion(){
  local VER=$($(which sshd)  -o 2>&1 | grep "OpenSSH_" | sed 's/OpenSSH_\([0-9]\+\.[0-9]\+\).*/\1/;')
  if [ -n "$VER" ] && version_ge $VER $1; then
    return 0
  else
    return 1
  fi
}

#-----------------------------------------------------------------------
# Configura para que a Umask seja usada em todas as conexões
# http://serverfault.com/questions/228396/how-to-setup-sshs-umask-for-all-type-of-connections
# http://linux-pam.org/Linux-PAM-html/sag-pam_umask.html
function SetUmask(){
  local UMASK=$1
  # Esta configuração funciona tanto no CentOS quanto no Ubuntu
  if ! grep "{NFAS-pamd.login}" /etc/pam.d/login; then
    echo -e "\n#{NFAS-pamd.login} Setting UMASK for all ssh based connections (ssh, sftp, scp)" >> /etc/pam.d/login
    echo "session    optional     pam_umask.so umask=$UMASK" >> /etc/pam.d/login
  fi
  if ! grep "{NFAS-pamd.sshd}" /etc/pam.d/sshd; then
    echo -e "\n#{NFAS-pamd.sshd} Setting UMASK for all ssh based connections (ssh, sftp, scp)" >> /etc/pam.d/sshd
    echo "session    optional     pam_umask.so umask=$UMASK" >> /etc/pam.d/sshd
  fi
  # OBS: também tem que alterar o UMASK para o Bash, senão sobrepõe o configurado no PAM.D
  #      a alteração do .bashrc, isso é feita pelo console.sh
}

#-----------------------------------------------------------------------
# Função para perguntar a Porta TCP para usar no SSH
# chamada: AskSshPort /etc/ssh/sshd_config
# Retorna: 0=ok, 1=Aborta se <Cancelar>
function AskSshPort(){
  local ERR_ST=""
  local PORT_TMP
  # Lê porta atuale verifica valor default=22
  local PORT_A=$(GetConfSpace $1 Port)
  [ -z $PORT_A ] && PORT_A=22
  # loop só sai com return
  while true; do
       MSG="\nDeseja mudar a Porta de acesso para o SSH?"
    MSG+="\n\nEsta alteração não afeta a segurança,"
      MSG+="\n  apenas reduz um pouco a estatística de tentativas de invasão"
      MSG+="\nPor este motivo NÃO É recomendado alterar (default=22)"
    MSG+="\n\n<Enter> para manter o anterior sendo mostrado\n"
    # Acrescenta mensagem de erro
    MSG+="\n$ERR_ST"
    # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
    PORT_A=$(whiptail --title "$TITLE" --inputbox "$MSG" 17 74 $PORT_A 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      echo "Operação cancelada!"
      ABORT="Y"
      return 1
    fi
    # Validação do nome, Testa se só tem dígitos
    PORT_TMP=$(echo $PORT_A | grep -E '^[0-9]{1,6}$')
    # Testa combinações inválidas
    if [ "$PORT_TMP" != "" ] &&                    # testa se vazio, pode ter sido recusado pela ER...
       [ $PORT_TMP -lt 65536 ] &&                  # Portas até 65535
       [ "$PORT_TMP" == "$PORT_A" ]; then # Não foi alterado pela ER
      # Email do Admin aceito, Continua
      echo "Porta do servidor de SSH ok: $PORT_A"
      SSH_PORT=$PORT_A
      return 0
    else
      ERR_ST="Porta inválida, por favor tente novamente"
    fi
  done
}


#-----------------------------------------------------------------------
# Configura fail2ban
# https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-centos-6
# Chamar APENAS no --first, congurações são fixas
function Fail2banConf(){
  local ARQ="/etc/fail2ban/jail.local"
  # O arquivo .local é lido depois do .conf para alterar seus prametros
  # Sempre é criado quando --first
  cat <<- EOF > $ARQ
		##################################################
		##  NFAS: configurações principais
		##################################################

		[DEFAULT]

		# "bantime" é o temo que um host fica banido
		bantime  = 600

		# "findtime" é o tempo corrido durante o qual são contadas as tentativas
		findtime  = 120

		# "maxretry" é o numero de tentativas permitidas +1
		maxretry = 4


		##################################################
		##  NFAS: configurações específicas do SSHD
		##################################################

		[ssh-iptables]

		enabled  = true
		filter   = sshd
		action   = iptables[name=SSH, port=$SSH_PORT, protocol=tcp]
		#           sendmail[name=SSH, dest=root, sender=fail2ban@$(hostname)]
		logpath  = /var/log/secure
		maxretry = 3
		EOF
  # Configura Exclusão se falhas máximas em 2 minutos
  # EditConfEqualSect $ARQ DEFAULT bantime  600
  # EditConfEqualSect $ARQ DEFAULT findtime 120
  #
  # configura arquivo de log
  EditConfEqualSect /etc/fail2ban/fail2ban.conf Definition logtarget "\\/var\\/log\\/fail2ban.log"
  # Opção para fazer o ban com DROP
  # https://github.com/fail2ban/fail2ban/issues/507
  ARQ="/etc/fail2ban/action.d/iptables-common.local"
  if [ ! -e "$ARQ" ]; then
    cp /etc/fail2ban/action.d/iptables-common.conf $ARQ
    chmod 600 $ARQ
  fi
  # blocktype define a maneira como é feito o bloqueio
  # não responde nada (demora para o cliente retornar): DROP
  # envia "Connection refused": REJECT --reject-with icmp-port-unreachable
  EditConfEqualSect $ARQ Init blocktype "REJECT --reject-with icmp-port-unreachable"
  # Reinicia
  service fail2ban reload
  # Configura Logrotate (ver no monit.sh)
  ARQ="/etc/logrotate.d/fail2ban"
  if [ ! -e $ARQ ]; then
    cat <<- EOF > $ARQ
		##################################################
		##  Logrotate para o fail2ban
		##################################################
		##  Depois de criado, não é mais alterado

		/var/log/fail2ban.log {
		  missingok
		  notifempty
		  compress
		  delaycompress
		  size 100k
		  weekly
		  create 0600 root root
		}
		EOF
  fi
  chmod 600 $ARQ
  # mensagem de confirmação
     MSG="\nProteção fail2ban configurada para"
  MSG+="\n\n  3 tentativas de login que falharem em 2 minutos"
    MSG+="\n  bloqueiam acesso daquele IP por 10 minutos"
    MSG+="\n  Emails de notificação desligados"
  MSG+="\n\n  configuração manual em /etc/fail2ban/jail.local"
  whiptail --title "$TITLE" --msgbox "$MSG" 13 70
}

#-----------------------------------------------------------------------
# Lê arquivo /etc/fail2ban/jail.local e retorna "Y" se envia Email
function GetFail2banEmail(){
  local TMP=$( eval "sed -n '/[ssh-iptables]/,/\[.*/ { /^[[:blank:]]*sendmail.*/p }' /etc/fail2ban/jail.local")
  if [ -n "$TMP" ]; then
    echo "Y"
  else
    echo "N"
  fi
}

#-----------------------------------------------------------------------
# Reconfigura IPTABLES para o SSH
function SetSshIptables(){
  # Porta default se não foi inicializada
  [ -z "$SSH_PORT" ] && SSH_PORT="22"
  # Limita conexões a 5 por minuto => Eliminado, gera mais problemas que resolve
  # iptables -A IN_SSH -p tcp --dport $SSH_PORT -m state --state NEW -m recent --set
  # iptables -A IN_SSH -p tcp --dport $SSH_PORT -m state --state NEW -m recent --update --seconds 60 --hitcount 5 -j DROP
  # Limpa chain especial do SSH, chain especial
  /sbin/iptables -F IN_SSH
  # Libera acesso à porta usada pelo SSH
  iptables -A IN_SSH -p tcp --dport $SSH_PORT -m state --state NEW -j ACCEPT
  # ídem para IPv6
  if which ip6tables >/dev/null; then
    ip6tables -A IN_SSH -p tcp --dport $SSH_PORT -m state --state NEW -j ACCEPT
  fi
}

#-----------------------------------------------------------------------
# Set KeyExchange options
# https://jbeekman.nl/blog/2015/05/ssh-logjam/
function SetKexOption(){
  local OPT=""
  if TestSshdVersion 6.7; then
    # This is available only from version 6.7
    OPT+="curve25519-sha256@libssh.org,"
  fi
  OPT+="ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group14-sha1"
  EditConfSpace $SSHD_ARQ KexAlgorithms $OPT
}

#-----------------------------------------------------------------------
# Salva variáveis de configuração
# Neste módulo as variáveis são usadas sempre apartir do arquivo de configuração Real
# Estas variáveis são guardadas apenas para recurso futuro de exportação
function SaveSshVars(){
  echo "SSH_PORT=\"$(GetConfSpace $SSHD_ARQ Port)\""                         2>/dev/null >  $VAR_FILE
  echo "SSH_PASS_AUTH=\"$(GetConfSpace $SSHD_ARQ PasswordAuthentication)\""  2>/dev/null >> $VAR_FILE
  echo "SSH_R_LOGIN=\"$(GetConfSpace $SSHD_ARQ PermitRootLogin)\""           2>/dev/null >> $VAR_FILE
  echo "SSH_F2B_EMAIL=\"$(GetFail2banEmail)\""                               2>/dev/null >> $VAR_FILE
}

#-----------------------------------------------------------------------
# Envia Email com as configurações de acesso SSH
# uso: SendEmailSshConf <user>
function SendEmailSshConf(){
  local USR=$1
  local NAME
  if [ "$USR" == "root" ]; then
    NAME=$(hostname -s)
  else
    NAME=$USR
  fi
  cat >/tmp/emailMsg.txt <<-EOT

	O seu comando para acesso remoto com chaves Pública/Privada por SSH é:
	----------
	    ssh -i ~/.ssh/$USR@$(hostname).key $USR@$(ifconfig eth0 | GetIpFromIfconfig)
	----------

	Preferívelmente configure seu aquivo .ssh/config para acesso simplificado.
	----------arquivo ~/.ssh/config
	# Configurações gerais recomendadas
	Host \*
	    ServerAliveInterval 30
	    IdentitiesOnly yes
	# Configuração de cada acesso (escolha um nome para Host)
	Host $NAME
	    User $USR
	    HostName $(ifconfig eth0 | GetIpFromIfconfig)
	    Port $SSH_PORT
	    IdentityFile ~/.ssh/$USR@$(hostname).key
	----------

	----------comando simplificado (mesmo nome que Host acima):
	    ssh $NAME
	----------

	ATENÇÃO: sua chave Privada foi gerada na sua própria máquina
	 no arquivo: .ssh/$USR@$(hostname).key
	 este arquivo fornece acesso total ao seu servidor. NÃO faça cópias!
	Gere uma chave diferente em cada máquina, assim é possível restringir
	  o acesso em caso de perda/roubo usando o comando "nfas"

	Enviado em: $(date +"%d/%m/%Y %H:%M:%S (%Z %z)")
	EOT
  # Envia usando email do sistema:
  cat /tmp/emailMsg.txt | mail -s "Comandos de Acesso - SSH" $EMAIL_ADMIN
  rm -f /tmp/emailMsg.txt
}

#-----------------------------------------------------------------------
# main()

# somente root pode executar este script
if [ "$(id -u)" != "0" ]; then
  echo "Somente root pode executar este comando"
  exit 255
fi

# Arquivo de configuração so SSHD
SSHD_ARQ=/etc/ssh/sshd_config

TITLE="NFAS - Configuração de SSH e acesso de ROOT"
if [ "$CMD" == "--first" ]; then
  if [ ! -e $SSHD_ARQ.orig ]; then
    cp  $SSHD_ARQ $SSHD_ARQ.orig
    chmod 600 $SSHD_ARQ
  fi
  # Durante instalação não mostra menus
  # Seta timeout para conexões SSH para 10 minutos sem responder
  # http://www.cyberciti.biz/tips/open-ssh-server-connection-drops-out-after-few-or-n-minutes-of-inactivity.html
  EditConfSpace $SSHD_ARQ ClientAliveInterval 30
  EditConfSpace $SSHD_ARQ ClientAliveCountMax 20
  # Garante uso exclusivo do protocolo v2
  EditConfSpace $SSHD_ARQ Protocol 2
  # Bloqueia modo antigo de autenticação simplificada
  EditConfSpace $SSHD_ARQ IgnoreRhosts yes
  # Evita Senhas em branco
  EditConfSpace $SSHD_ARQ PermitEmptyPasswords no
  # http://www.unixlore.net/articles/five-minutes-to-more-secure-ssh.html
  EditConfSpace $SSHD_ARQ ChallengeResponseAuthentication no
  # LONGJAM vulnerability
  SetKexOption
  # Altera Porta do SSH, var: SSH_PORT
  AskSshPort $SSHD_ARQ
  EditConfSpace $SSHD_ARQ Port $SSH_PORT
  # Precisa salvar para Email que será enviado com dados de acesso
  SaveSshVars
  # Reconfigura iptables, caso tenha atualização
  SetSshIptables
  # Novo certificado de root
  AskNewKey root /root
  # precisa restart (?)
  service sshd restart
  # Configura para que a Umask
  SetUmask 007
  # mensagem para bloqueio de acesso mas tarde
     MSG="\nConfiguração inicial de acesso:"
    MSG+="\n  Acesso via SSH por senha: permitido"
    MSG+="\n  Acesso via SSH como usuário ROOT: permitido"
    MSG+="\n  Acesso ao SSH pela porta TCP=$SSH_PORT"
    MSG+="\n  Uso exclusivo do protocolo v2"
    MSG+="\n  Não permite usar senha vazia"
    MSG+="\n  Bloquada autenticaçao Rhost e Chalenge (antiga)"
    MSG+="\n  Bloqueada vilnerabilidade LongJam"
    # MSG+="\n  Bloquada mais que 5 acessos por minuto (por IP)"
  MSG+="\n\nUtilize o comando \"nfas\" após terminar a instalação"
    MSG+="\ne somente APÓS testar os acessos!!!"
  whiptail --title "$TITLE" --msgbox "$MSG" 19 70
  # Configura FAIL2BAN
  Fail2banConf
  # Salva variáveis de configuração
  SaveSshVars

elif [ "$CMD" == "--firewall" ]; then
  #-----------------------------------------------------------------------
  # Durante o boot precisa reconfigurar a porta do SSH
  SetSshIptables
  # Recria a chain no começo do INPUT
  service fail2ban reload

elif [ "$CMD" == "--hostname" ]; then
  #-----------------------------------------------------------------------
  # Foi alterado Hostname, precisa corrigir o fail2ban
  eval "sed -i '/[ssh-iptables]/,/\[.*/ { s/^\(.*sender=fail2ban@\).*\(]\)$/\1$(hostname)\2/ }' /etc/fail2ban/jail.local"
  service fail2ban reload

elif [ "$CMD" == "--email" ]; then
  #-----------------------------------------------------------------------
  # Envia Email com instruções de acesso
  SendEmailSshConf $2
else
  #-----------------------------------------------------------------------
  # Loop do Menu principal interativo
  while true; do
    # Mostra Menu
    PASS_AUTH=$(GetConfSpace $SSHD_ARQ PasswordAuthentication)
    if [ "$PASS_AUTH" == "yes" ]; then
      MSG_SSH_SENHA="Bloquear acesso pelo SSH com senha,     ATUAL=permitido"
    else
      MSG_SSH_SENHA="Permitir acesso pelo SSH com senha,     ATUAL=bloquado"
    fi
    R_LOGIN=$(GetConfSpace $SSHD_ARQ PermitRootLogin)
    if [ "$R_LOGIN" == "yes" ]; then
      MSG_ROOT_SSH="Bloquear acesso de root pelo SSH,       ATUAL=permitido"
    else
      MSG_ROOT_SSH="Permitir acesso de root pelo SSH,       ATUAL=bloquado"
    fi
    SSH_PORT=$(GetConfSpace $SSHD_ARQ Port)
    [ -z $SSH_PORT ] && SSH_PORT=22
      MSG_PORT_SSH="Porta TCP para acesso ao SSH,           ATUAL=$SSH_PORT"
    if [ "$(GetFail2banEmail)" == "Y" ]; then
      MSG_F2B_MAIL="Bloquear envio de Emails pelo FAIL2BAN, ATUAL=enviando"
    else
      MSG_F2B_MAIL="Permitir envio de Emails pelo FAIL2BAN, ATUAL=parado"
    fi
    MENU_IT=$(whiptail --title "$TITLE" --cancel-button "Retornar" \
        --menu "\nSelecione um comando de reconfiguração:" --fb 18 70 6   \
        "1" "Acrescentar Chave Pública (PublicKey)"    \
        "2" "Listar/Remover Chave Pública (PublicKey)" \
        "3" "$MSG_SSH_SENHA"                           \
        "4" "$MSG_ROOT_SSH"                            \
        "5" "$MSG_PORT_SSH"                            \
        "6" "$MSG_F2B_MAIL"                            \
        3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
        echo "Seleção cancelada."
        exit 0
    fi
    # Funções que ficam em Procedures
    # Novo certificado de root
    [ "$MENU_IT" == "1" ] && AskNewKey root /root
    # Remove certificado de root
    [ "$MENU_IT" == "2" ] && DeleteKeys root /root

    # altera Acesso com senha
    if [ "$MENU_IT" == "3" ]; then
      if [ "$PASS_AUTH" != "yes" ]; then
        # Libera acesso por senha
        EditConfSpace $SSHD_ARQ PasswordAuthentication yes
        # Recarrega o SSHD para usar novo paremetro
        service sshd restart
      else
        # Le o tipo de Login: password ou publickey
        LOGIN_TYPE=$(GetLoginType)
        if [ "$LOGIN_TYPE" == "publickey" ]; then
          EditConfSpace $SSHD_ARQ PasswordAuthentication no
          # Recarrega o SSHD para usar novo paremetro
          service sshd restart
        else
             MSG="\nVocê precisa ter feito um login com chaves Píblica/Privada"
            MSG+="\n  para poder setar esta opção..."
          MSG+="\n\nEsta é uma medida de segurança para evitar"
            MSG+="\n  que você se tranque para fora ;)"
          whiptail --title "$TITLE" --msgbox "$MSG" 12 70
        fi
      fi
    fi

    # Altera acesso de root
    if [ "$MENU_IT" == "4" ]; then
      [ "$R_LOGIN" == "yes" ] && TMP="no" || TMP="yes"
      EditConfSpace $SSHD_ARQ PermitRootLogin $TMP
      # Recarrega o SSHD para usar novo paremetro
      service sshd restart
    fi

    # Altera Porta do SSH
    if [ "$MENU_IT" == "5" ]; then
      AskSshPort $SSHD_ARQ
      PORT_A=$(GetConfSpace $1 Port)
      if [ "$PORT_A" != "$SSH_PORT" ]; then
        # Reconfigura Firewall, chain especial
        SetSshIptables
         # Altera porta do SSH
        EditConfSpace $SSHD_ARQ Port $SSH_PORT
        service sshd restart
        # Altera Porta do Fail2ban
        eval "sed -i '/\[ssh-iptables\]/,/\[.*/ { s/^\(.*port=\).*\(,.*\)$/\1$SSH_PORT\2/ }' /etc/fail2ban/jail.local"
        service fail2ban reload
      fi
    fi

    # Envio de Emails do Fail2ban
    if [ "$MENU_IT" == "6" ]; then
      if [ "$(GetFail2banEmail)" == "Y" ]; then
        eval "sed -i '/[ssh-iptables]/,/\[.*/ { s/^\([[:blank:]]*sendmail.*\)/#\1/ }' /etc/fail2ban/jail.local"
      else
        eval "sed -i '/[ssh-iptables]/,/\[.*/ { s/^#\([[:blank:]]*sendmail.*\)/\1/ }' /etc/fail2ban/jail.local"
      fi
      service fail2ban reload
    fi
    # Salva variáveis de configuração
    SaveSshVars
    # Reconfigura Estado do sistema
    /script/boot/90-state.sh
    # read -p "Enter para continuar..." TMP
  done # loop menu principal
fi # --first

