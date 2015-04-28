#!/bin/bash
set -x

# Script para (re)configurar sistema de monitoramento com MONIT
# O que monitorar: memória, espaço em disco, inodes, cpu, network

# ==> Precisa compilar última versão para poder monitorar tráfego de rede
# O mesmo Script é usado para a primeira vez e para alterar a configuração
# Chamada: "/script/monit.sh <cmd>"
# <cmd>: --first     durante primeira instalação, chamada pelo email.sh
#        --email     alteradas configurações de email, só se alteração posterior
#        --hostname  quando foi alterado hostname, só se alteração posterior

# Testar configuração: monit validate
# Serviço: start|stop|status monit
# Informações: monit status
# Alteração: monit reload
# Para ver o log: tail -f /var/log/monit
# Acesso http: sshpass -p nodejs ssh -f root@192.168.0.207 -L 2000:192.168.0.207:2812 -N
#              xdg-open http://localhost:2000/

# https://mmonit.com/monit/documentation/monit.html
# http://airbladesoftware.com/notes/managing-monit-with-upstart/

#-----------------------------------------------------------------------
# comandos manuais para verificação:
# instala programas pequenos e úteis:
yum -y install htop nmon

# free                 # Mostra Memória realmente utilizada (sem os buffers)
# df -h                # Uso dos discos
# df -ih               # Uso de  iNodes
# NMON=cmn nmon        # Uso de recursos,http://nmon.sourceforge.net/pmwiki.php
# htop                 # versão melhorada do top

#-----------------------------------------------------------------------
# Processa a linha de comando
CMD=$1
# usa as variaveis armazenadas
. /script/info/hostname.var
. /script/info/email.var
. /script/info/distro.var

#-----------------------------------------------------------------------
# Instala apartir dos fontes

if [ "$CMD" == "--first" ]; then
  # pacotes para compilar e dependencias
  yum -y install openssl openssl-devel pam pam-devel gcc make
  # Compila num diretório próprio
  mkdir -p /script/monit
  pushd /script/monit      # Vai para diretório mas lembra do anterior
  wget http://mmonit.com/monit/dist/monit-5.12.tar.gz
  tar xfv monit-5.12.2.tar.gz
  cd monit-5.12/
  ./configure --prefix=/usr --sysconfdir=/etc/monit
  make clean
  make
  make install
  # OBS: o comando "monit -t" mostra onde deve estar o arquivo de configuração:
  #   Cannot find the control file at ~/.monitrc, /etc/monitrc, /etc/monit/monitrc, /usr/local/etc/monitrc or at ./monitrc

  #-----------------------------------------------------------------------
  # configuração básica
  mkdir -p /etc/monit
  cp -af monitrc /etc/monit/monitrc.orig   # Preserva o original
  ARQ="/etc/monit/monitrc"
  cat <<- EOF > $ARQ
	###############################################################################
	## Monit control file
	###############################################################################
	##
	# Configurações próprias do NFAS, por favor não altera manualmente

	## Start Monit in the background (run as a daemon):
	#
	set daemon  60              # check services at 1-minute intervals

	# Precisa configura HTTP do Monit para acesso mínimo
	# Como usa apenas por Tunnel do SSH, libera todos os IPs
	#
	set httpd port 2812
		allow localhost        # allow localhost to connect to the server (comando monit status)
		allow 0.0.0.0/0        # Permite acesso via SshTunnel (preserva o IP)

	## It is possible to include additional configuration parts from other files or
	## directories.
	#
	include /etc/monit/monit.d/*
	#
	EOF
  chmod 600 $ARQ
  # Diretório de includes para configurações de cada recurso
  mkdir -p /etc/monit/monit.d

  popd      # Volta ao diretório original
  # rm -fd /script/monit
fi #--first

#-----------------------------------------------------------------------
# Envio de Email para o administrador

ARQ="/etc/monit/monit.d/email.monit"
if [ ! -e $ARQ ]; then
  cat <<- EOF > $ARQ
	##################################################
	##  Monit: Configuração de Email do admin
	##################################################
	##  Depois de criado, não é mais alterado

	set mailserver localhost port 25
	  with timeout 30 seconds
	set alert root@localhost with reminder on 30 cycles
	EOF
fi
chmod 600 $ARQ

#-----------------------------------------------------------------------
# Monitoramento de recursos de CPU, disco e memória
# Se o arquivo existe não altera!

ARQ="/etc/monit/monit.d/system.monit"
if [ ! -e $ARQ ]; then
  cat <<- EOF > $ARQ
	##################################################
	##  Monit: Configuração de Cpu, disco e memória
	##################################################
	##  Depois de criado, não é mais alterado

	check system SystemCheck
	  if loadavg (1min) > 4 then alert
	  if loadavg (5min) > 2 then alert
	  if memory usage > 75% then alert
	  if cpu usage (user) > 70% then alert
	  if cpu usage (system) > 30% then alert
	  if cpu usage (wait) > 20% then alert

	check filesystem FilesystemCheck with path /
	  # Só para testes (usar 75%)
	  if space usage > 3% then alert
	  if inode usage > 80% then alert
	EOF
# else
#   sed -i "/check system/s/\(.*system\.\).*/\1$HOSTNAME_INFO/g" $ARQ
#   sed -i "/check filesystem/s/\(.*rootfs\.\)[^ ]*\( .*\)/\1$HOSTNAME_INFO\2/g" $ARQ
fi
chmod 600 $ARQ

#-----------------------------------------------------------------------
# Formatação do Email enviado
# Se o arquivo existe não altera!

ARQ="/etc/monit/monit.d/format.monit"
if [ ! -e $ARQ ]; then
  echo "##################################################"               >  $ARQ
  echo "##  Monit: Formatação do email de notificação"                    >> $ARQ
  echo "##################################################"               >> $ARQ
  echo "##  Depois de criado, apenas a linha com o Hostname é alterada"   >> $ARQ
  echo ""                                        >> $ARQ
  echo "set mail-format {"                       >> $ARQ
  echo "  from: monit@$HOSTNAME_INFO"            >> $ARQ
  echo "  subject: [MONIT] \$SERVICE: \$EVENT"   >> $ARQ
  echo "  message:"                              >> $ARQ
  echo "Evento: \$EVENT"                         >> $ARQ
  echo "Servico: \$SERVICE"                      >> $ARQ
  echo ""                                        >> $ARQ
  echo "  Descricao:	\$DESCRIPTION"           >> $ARQ
  echo "  Host:		$HOSTNAME_INFO"              >> $ARQ
  echo "  Action:		\$ACTION"                >> $ARQ
  echo ""                                        >> $ARQ
  echo "Data: \$DATE"                            >> $ARQ
  echo "}"                                       >> $ARQ
else
  sed -i "/from:/s/\(.*@\)[^ ]*.*/\1$HOSTNAME_INFO/g" $ARQ
  sed -i "/Host:/s/\(^[[:blank:]]*Host:[[:blank:]]*\)[^ ]*.*/\1$HOSTNAME_INFO/g" $ARQ
fi
chmod 600 $ARQ

#-----------------------------------------------------------------------
# Monitora uso da Rede

ARQ="/etc/monit/monit.d/network.monit"
if [ ! -e $ARQ ]; then
  cat <<- EOF > $ARQ
	##################################################
	##  Monit: Configuração Uso da rede
	##################################################
	##  Depois de criado, não é mais alterado

	check network NetTraffic with interface eth0
	  # Download: para o próprio servidor (ex: yum update)
	  if download > 100 kB/s then alert
	  # Upload: alguém baixando arquivo DO servidor
	  # Tráfego 1TB/mes, 50%, 15GB/dia, 700MB/hora
	  if total upload > 700 MB in last 1 hours then alert
	  if total upload > 15 GB in last day then alert
	  # Só para testes
	  if total upload > 5 MB in last minute then alert
	  if saturation > 90% then alert
	EOF
fi
chmod 600 $ARQ


#-----------------------------------------------------------------------
# Instala com o UPSTART
# OBS: só para "CentOS 6" e talvez Ubuntu14.04, CentOS 7 usa SYSTEMD

if [ "$DISTRO_NAME_VERS" == "CentOS 6" ]; then
  # remove o arquivo do init.d se existir
  [ -e /etc/init.d/monit ] && /etc/init.d/monit stop
  rm -f /etc/init.d/monit
  ARQ="/etc/init/monit.conf"
  cat <<- EOF > $ARQ
	#!upstart

	description "Monit"

	start on runlevel [2345]
	stop on shutdown
	respawn

	# Roda sem ser como daemon para o respawn funcionar
	exec monit -I
	EOF
  # Não pode usar "restart", precisa saber se está rodando para poder dar "stop"
  if ( status monit | grep start ); then
    stop monit
  fi
  start monit
fi

#-----------------------------------------------------------------------
