#!/bin/bash

# Atenção, se deixat p "set -x" ativo, gera email diário do cron
# set -x

# Script para Configurar o RTC e localtime
# As perguntas são interativas através de TUI
# Uso: /script/ssh.sh <cmd>
# <cmd>: --first       primeira instalação
#        --localtime   seleciona localtime
#        --daily       chamado por /etc/cron.daily
#        <em branco>   só altera localtime

# O RTC tem que ficar ajustado e sincronizado por NTP
# O NTP precisa usar servidores em grupos de vários continentes,
#    o sistema automáticamente seleciona os mais próximos.
#    Vários de cada grupo com origens diferentes são para redundancia.
# O localtime pode ser configurado para facilitar o uso do CRON
#    pelo administrador na sua hora local

# Configuração do clock no CentOS 6
# http://dev.chetankjain.net/2012/04/fixing-date-time-and-zone-on-rhel-6.html?m=1
# http://thornelabs.net/2013/04/25/rhel-6-manually-change-time-zone.html
# https://www.centos.org/docs/5/html/5.1/Deployment_Guide/s2-sysconfig-clock.html

#=======================================================================
# Processa a linha de comando
CMD=$1

# Funções auxiliares
. /script/functions.sh
# Lê dados anteriores se existirem
. /script/info/distro.var
VAR_FILE="/script/info/clock.var"
[ -e $VAR_FILE ] && . $VAR_FILE

# o NTP chama o serviço de "ntp" no Debian/Ubuntu e "ntpd" no CentOS
if [ "$DISTRO_NAME" == "CentOS" ]; then
  NTP=ntpd
else
  NTP=ntp
fi

#-----------------------------------------------------------------------
# Configura o RTC (harware) para UTC
function RtcSetUtc(){
  # Altera RTC (hardware) para UTC (atualiza o /etc/adjtime)
  hwclock --systohc --utc
  # no CentOS alterou /etc/adjtime (testar no Ubuntu)
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    # Indica configuração UTC no /etc/sysconfig/clock
    EditConfEqualSafe /etc/sysconfig/clock UTC yes
  else
    # No Ubunttu é /etc/default/rcS
    # http://askubuntu.com/questions/115963/how-do-i-migrate-to-utc-hardware-clock
    echo "Ubuntu não implementado"
  fi
  # Acerta a nova hora usando servido ntp
  service $NTP stop
  ntpdate 0.us.pool.ntp.org
}

#-----------------------------------------------------------------------
# Configura o NTP
# Brasil: http://ntp.br/guia-linux-avancado.php
# USA: http://www.pool.ntp.org/zone/us
# Europa: http://www.pool.ntp.org/pt/zone/europe
# CentOS 7: talvez use chrony em vez do ntpd (?)

function NtpConfigure(){
  local NTP_ARQ=/etc/ntp.conf
  # Guarda arquivo original
  if [ ! -e $NTP_ARQ.orig ]; then
    cp  $NTP_ARQ $NTP_ARQ.orig
    chmod 600 $NTP_ARQ.orig
  fi
  # para o ntpd para reconfigurar
  service $NTP stop
  # Cria arquivo drift para habilitar a funcionalidade
  #   http://magazine.redhat.com/2007/02/06/why-do-i-get-cant-open-etcntpdrifttemp-permission-denied-entries-in-varlogmessages-when-i-use-ntpd/
  touch /var/lib/ntp/drift
  # a hora já foi sincronizada ao configurar UTC
  #(não) ntpdate 0.us.pool.ntp.org
  # cria arquivo de configuração
  if [ ! -e $NTP_ARQ ]; then
    cat <<- EOF > $NTP_ARQ
		##################################################
		##  Configuração do NTPD
		##################################################
		##  Depois de criado, não é mais alterado

		# "memoria" para o ajuste automático da frequencia do micro
		driftfile /var/lib/ntp/drift

		# estatisticas não configuradas

		# Seguraça: configuracoes de restricão de acesso
		restrict default kod notrap nomodify nopeer noquery
		restrict -6 default kod notrap nomodify nopeer noquery
		# Seguraça: desabilitar comando monlist
		disable monitor

		# servidores públicos do projeto ntp.br
		server a.st1.ntp.br iburst
		server b.st1.ntp.br iburst
		server c.st1.ntp.br iburst
		server d.st1.ntp.br iburst
		server gps.ntp.br iburst
		server a.ntp.br iburst
		server b.ntp.br iburst
		server c.ntp.br iburst

		# Servidores nos USA, são 600 servidores
		server 0.us.pool.ntp.org iburst
		server 1.us.pool.ntp.org iburst
		server 2.us.pool.ntp.org iburst
		server 3.us.pool.ntp.org iburst

		# Servidores na Europa
		server 0.europe.pool.ntp.org iburst
		server 1.europe.pool.ntp.org iburst
		server 2.europe.pool.ntp.org iburst
		server 3.europe.pool.ntp.org iburst

		# Servidores na Asia
		server 0.asia.pool.ntp.org
		server 1.asia.pool.ntp.org
		server 2.asia.pool.ntp.org
		server 3.asia.pool.ntp.org

		EOF
  fi
  chmod 600 $NTP_ARQ
  # Configura o NTP para próximo boot
  chkconfig ntpd on
  # re-ativa o ntpd
  service $NTP start
  # Mensagem de aviso informativo
     MSG="\nSeu relógio RTC (harware) foi configurado para UTC"
  MSG+="\n\nO Relógio ficará sicronizado usando o NTP"
    MSG+="\n  Foran configurados servidores que serão selecionados"
    MSG+="\n  automáticamente para intalações na núvem em 4 continentes:"
    MSG+="\n  Brasil, USA, Europa e Asia"
  whiptail --title "$TITLE" --msgbox "$MSG" 13 70
}

#-----------------------------------------------------------------------
# Configura o localtime - Fuso horário
# http://unix.stackexchange.com/questions/189632/read-the-last-line-of-tzselect

function SysLocaltime(){
  local NEW_TZ
  # Pergunta se quer ajustar UTC ou localtime
     MSG="\nConfiguração do localtime ou Fuso Horário"
  MSG+="\n\nO Fuso Horario atual é: $(GetLocaltime)"
  MSG+="\n\nEste define a hora local do sistema e controla o agendamento do CRON"
  MSG+="\nPara maior comodidade, pode ser usado o local do administrador"
  MENU_IT=$(whiptail --title "$TITLE"      \
      --menu "$MSG" --fb 19 74 3           \
      "1" "Selecionar o Fuso Horário"      \
      "2" "Usar a hora do sistema em UTC"  \
      "3" "Manter a configuração Atual"    \
      3>&1 1>&2 2>&3)
  if [ $? != 0 ]; then
      echo "Seleção cancelada."
      return 0
  fi

  # Pergunta Time Zone
  if [ "$MENU_IT" == "1" ];then
    while true; do
      clear
      NEW_TZ=$(tzselect)
      SetLocaltime $NEW_TZ
      # Pode retornar erro se o arquivo não existe
      if [ $? == 0 ]; then
        return 0
      else
        # Arquivo retornado por tzselect não existe
           MSG="\nOcorreu um erro inesperado para esta Zona."
        MSG+="\n\nSe o erro persistir, selecione outra..."
        whiptail --title "$TITLE" --msgbox "$MSG" 9 70
      fi
    done # loop se erro
  fi

  # Sistema em UTC
  if [ "$MENU_IT" == "2" ];then
    SetLocaltime UTC
  fi
  # Mantém atual
  if [ "$MENU_IT" == "3" ];then
    return 0
  fi
}

#-----------------------------------------------------------------------
# main()

TITLE="NFAS - Configuração do Relógio"
if [ "$CMD" == "--first" ]; then
  # Altera RTC (hardware) para UTC
  RtcSetUtc
  # Configura NTP
  NtpConfigure
  # cria chamada diária
  ARQ=/etc/cron.daily/nfas-clock.sh
    cat <<- EOF > $ARQ
		#!/bin/bash

		##################################################
		##  Reconfiguração do RTC
		##################################################

		# Chama diariamente para sincronizar o RTC (hardware clock)

		/script/clock.sh --daily

		EOF
  chmod 700 $ARQ
  # Seleciona o localtime
  SysLocaltime

elif [ "$CMD" == "--daily" ]; then
  #-----------------------------------------------------------------------
  # Ajustes diários, sincroniza relógio de harware
  # https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/sect-Configuring_the_Date_and_Time-hwclock.html
  hwclock --systohc

elif [ "$CMD" == "--localtime" ]; then
  #-----------------------------------------------------------------------
  # Pode ser chamado externamente (pelo nfas.sh) para alterar Fuso Horário
  SysLocaltime

else
  #-----------------------------------------------------------------------
  # Ajuste interativo, só localtime
  SysLocaltime
  echo ""
fi

#-----------------------------------------------------------------------
