#!/bin/bash
set -x

# Script para Configurar o RTC e localtime
# As perguntas são interativas através de TUI
# Uso: /script/ssh.sh <cmd>
# <cmd>: --first       primeira instalação
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

#-----------------------------------------------------------------------
# Configura o RTC (harware) para UTC
function RtcSetUtc(){
  # Altera RTC (hardware) para UTC
  hwclock systohc --utc
  # no CentOS alterou /etc/adjtime (testar no Ubuntu)
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    # Indica configuração UTC no /etc/sysconfig/clock
    EditConfEqual /etc/sysconfig/clock UTC yes
  else
    # No Ubunttu é /etc/default/rcS
    # http://askubuntu.com/questions/115963/how-do-i-migrate-to-utc-hardware-clock
    echo "Ubuntu não implementado"
  fi
  # Acerta a nova hora usando servido ntp
  ntpdate 0.us.pool.ntp.org
}

#-----------------------------------------------------------------------
# Configura o NTP
# Brasil: http://ntp.br/guia-linux-avancado.php
# USA: http://www.pool.ntp.org/zone/us
# Europa: http://www.pool.ntp.org/pt/zone/europe

function NtpConfigure(){
  local NTP_ARQ=/etc/ntp.conf
  # Guarda arquivo original
  if [ ! -e $NTP_ARQ.orig ]; then
    cp  $NTP_ARQ $NTP_ARQ.orig
    chmod 600 $NTP_ARQ
  fi
  # para o ntpd para reconfigurar
  service ntpd stop
  # Cria arquivo drift para habilitar a funcionalidade
  touch /etc/ntp.drift
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
		driftfile /etc/ntp.drift

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
  # re-ativa o ntpd
  service ntpd start
  # Mensagem de aviso informativo
     MSG="\nSeu relógio RTC (harware) foi configurado para UTC"
  MSG+="\n\nO Relógio ficará sicronizado usando o NTP"
    MSG+="\n  Foran configurados servidores que serão selecionados"
    MSG+="\n  automáticamente em 4 continentes:"
    MSG+="\n  Brasil, USA, Europa e Asia"
  whiptail --title "$TITLE" --msgbox "$MSG" 13 70
}

#-----------------------------------------------------------------------
# main()

TITLE="NFAS - Configuração do Relógio"
if [ "$CMD" == "--first" ]; then
  # Altera RTC (hardware) para UTC
  RtcSetUtc
  # Configura NTP
  NtpConfigure
else
  #-----------------------------------------------------------------------
  # Ajuste interativo, só localtime

fi

#-----------------------------------------------------------------------
