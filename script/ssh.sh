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

#=======================================================================
# Processa a linha de comando
CMD=$1
# Funções auxiliares
. /script/functions.sh
# Lê dados anteriores se existirem
. /script/info/distro.var
VAR_FILE="/script/info/ssh.var"
[ -e $VAR_FILE ] && . $VAR_FILE

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
  # Altera UMASK para o bash, senão sobrepõe o configurado no PAM.D
  # Alterando o .bashrc funciona  tanto no CentOS quanto no Ubuntu
  if ! grep "{NFAS-bash.umask}" /root/.bashrc; then
    echo -e "\n#{NFAS-bash.umask} Configura máscara para criação de arquivos sem acesso a \"outros\"" >> /root/.bashrc
    echo "umask $UMASK" >> /root/.bashrc
  fi
}

#-----------------------------------------------------------------------
# Configura fail2ban
# https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-centos-6
# Chamar APENAS no --first, congurações são fixas
function Fail2banConf(){
  local ARQ="/etc/fail2ban/jail.local"
  if [ ! -e "$ARQ" ]; then
    cp /etc/fail2ban/jail.conf $ARQ
    chmod 600 $ARQ
  fi
  # Configura Exclusão se falhas máximas em 2 minutos
  EditConfIgual $ARQ DEFAULT bantime  600
  EditConfIgual $ARQ DEFAULT findtime 120
  # configura arquivo de log
  EditConfIgual /etc/fail2ban/fail2ban.conf Definition logtarget "\\/var\\/log\\/fail2ban.log"
  # Configurações específicas do SSHD
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    if ! grep "\[ssh-iptables\]" $ARQ; then
      cat <<- EOF >> $ARQ

			##################################################
			##  NFAS: configurações específicas do SSHD
			##################################################

			[ssh-iptables]

			enabled  = true
			filter   = sshd
			action   = iptables[name=SSH, port=ssh, protocol=tcp]
			           sendmail[name=SSH, dest=root, sender=fail2ban@$(hostname)]
			logpath  = /var/log/secure
			maxretry = 3
			EOF
    fi
  fi
  # Reinicia
  service fail2ban restart
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
  MSG+="\n\n  3 falhas em 2 minutos bloqueiam acesso por 10 minutos"
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
# main()

# somente root pode executar este script
if [ "$(id -u)" != "0" ]; then
  echo "Somente root pode executar este comando"
  exit 255
fi
TITLE="NFAS - Configuração de SSH e acesso de ROOT"
if [ "$CMD" == "--first" ]; then
  ARQ=/etc/ssh/sshd_config
  if [ ! -e $ARQ.orig ]; then
    cp  $ARQ $ARQ.orig
    chmod 600 $ARQ
  fi
  # Durante instalação não mostra menus
  # Novo certificado de root
  AskNewKey root /root
  # Seta timeout para conexões SSH para 10 minutos sem responder
  # http://www.cyberciti.biz/tips/open-ssh-server-connection-drops-out-after-few-or-n-minutes-of-inactivity.html
  EditConfSpace $ARQ ClientAliveInterval 30
  EditConfSpace $ARQ ClientAliveCountMax 20
  service sshd reload
  # Configura para que a Umask
  SetUmask 007
  # mensagem para bloqueio de acesso mas tarde
     MSG="\nPara fazer o bloqueio:"
    MSG+="\n  Acesso via SSH por senha"
    MSG+="\n  Acesso via SSH como usuário ROOT"
  MSG+="\n\nutilize o comando \"nfas\" após terminar a instalação"
    MSG+="\ne somente após testar os acessos!!!"
  whiptail --title "$TITLE" --msgbox "$MSG" 13 70
  # Configura FAIL2BAN
  Fail2banConf
else
  #-----------------------------------------------------------------------
  # Loop do Monu principal interativo
  while true; do
    # Mostra Menu
    PASS_AUTH=$(GetConfSpace /etc/ssh/sshd_config PasswordAuthentication)
    if [ "$PASS_AUTH" == "yes" ]; then
      MSG_SSH_SENHA="Bloquear acesso pelo SSH com senha,     ATUAL=permitido"
    else
      MSG_SSH_SENHA="Permitir acesso pelo SSH com senha,     ATUAL=bloquado"
    fi
    R_LOGIN=$(GetConfSpace /etc/ssh/sshd_config PermitRootLogin)
    if [ "$R_LOGIN" == "yes" ]; then
      MSG_ROOT_SSH="Bloquear acesso de root pelo SSH,       ATUAL=permitido"
    else
      MSG_ROOT_SSH="Permitir acesso de root pelo SSH,       ATUAL=bloquado"
    fi
    if [ "$(GetFail2banEmail)" == "Y" ]; then
      MSG_F2B_MAIL="Bloquear envio de Emails pelo FAIL2BAN, ATUAL=enviando"
    else
      MSG_F2B_MAIL="Permitir envio de Emails pelo FAIL2BAN, ATUAL=parado"
    fi
    MENU_IT=$(whiptail --title "$TITLE" \
        --menu "\nSelecione um comando de reconfiguração:" --fb 18 70 5   \
        "1" "Acrescentar Chave Pública (PublicKey)"  \
        "2" "Remover Chave Pública (PublicKey)"      \
        "3" "$MSG_SSH_SENHA"                         \
        "4" "$MSG_ROOT_SSH"                          \
        "5" "$MSG_F2B_MAIL"                          \
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
      [ "$PASS_AUTH" == "yes" ] && TMP="no" || TMP="yes"
      EditConfSpace /etc/ssh/sshd_config PasswordAuthentication $TMP
      # Recarrega o SSHD para usar novo paremetro
      service sshd reload
    fi

    # Altera acesso de root
    if [ "$MENU_IT" == "4" ]; then
      [ "$R_LOGIN" == "yes" ] && TMP="no" || TMP="yes"
      EditConfSpace /etc/ssh/sshd_config PermitRootLogin $TMP
      # Recarrega o SSHD para usar novo paremetro
      service sshd reload
    fi

    if [ "$MENU_IT" == "5" ]; then
      if [ "$(GetFail2banEmail)" == "Y" ]; then
        eval "sed -i '/[ssh-iptables]/,/\[.*/ { s/^\([[:blank:]]*sendmail.*\)/#\1/ }' /etc/fail2ban/jail.local"
      else
        eval "sed -i '/[ssh-iptables]/,/\[.*/ { s/^#\([[:blank:]]*sendmail.*\)/\1/ }' /etc/fail2ban/jail.local"
      fi
      service fail2ban reload
    fi
    # read -p "Enter para continuar..." TMP
  done # loop menu principal
fi # else --first

