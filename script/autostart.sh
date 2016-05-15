#!/bin/bash

# Script executado automáticamente quando reinicia o servidor.
# Chamada pelo /etc/rc.d/rc.local (no CentOS é diferente...)
#
# Essa chamada é configurada quando executa o /script/first.sh
# Uso:
# /script/ssh.sh --first       durante primeira instalação
# /script/ssh.sh <sem nada>    chamada pelo /etc/rc.d/rc.local no boot


# Processa a linha de comando
CMD=$1
# Inclui funções básicas
. /script/functions.sh

#-----------------------------------------------------------------------
# Executa arquivos no /script/boot na ordem
function ExecBootScripts(){
  FILES=$(ls /script/boot/*.sh)
  for f in $FILES; do
    echo "Chamando $f" >> /script/info/autostart.log
    # usa o su para criar um login-shell, está rodando num ambiente não padrão
    su -l -c $f
  done
}

#=======================================================================
# MAIN
if [ "$CMD" == "--first" ]; then
  # Durante a instalação, executa scripts do boot
  ExecBootScripts
else
  # Boot normal
  echo "Rodando o Script de inicialização: /script/autostart.sh" > /script/info/autostart.log

  #-----------------------------------------------------------------------
  # Mostra IP na tela de boot
  #
  MY_IP=$(ifconfig eth0 |GetIpFromIfconfig)
  MSG="\n IP atual:"
  if [ -z "$(sed -n '/IP atual/p' /etc/issue)" ]; then
    # primeira vez
    echo -e " IP atual: $MY_IP\n" >> /etc/issue
  else
    # altera existente
    sed -i "s/\(^[[:blank:]]*IP atual[[:blank:]]*:\)\(.*\)/\1 $MY_IP/" /etc/issue
  fi

  #-----------------------------------------------------------------------
  # quando troca o MAC no CentOS, a placa de rede troca de nome para eth1, eth2, etc.
  # elimina informação da placa para evitar a troca de nome, tem que fazer a cada boot
  # Só no Virtualbox e CentOS
  . /script/info/virtualbox.var
  . /script/info/distro.var
  if [ "$IS_VIRTUALBOX" == "Y" ] && [ "$DISTRO_NAME" == "CentOS" ]; then
    echo "#" > /etc/udev/rules.d/70-persistent-net.rules
    sed -i /HWADDR/d /etc/sysconfig/network-scripts/ifcfg-eth0
  fi

  #-----------------------------------------------------------------------
  # evita apagamento da tela, tanto para VM quanto para console remoto
  # http://superuser.com/questions/152347/change-linux-console-screen-blanking-behavior
  # cada sistema tem um método, depente se usa init.d, upstart ou systemd
  if [ "$DISTRO_NAME_VERS" == "CentOS 6" ]; then
    for term in /dev/tty[0-9]*; do # select all ttyNN, but skip ttyS*
      setterm -blank 0 -powersave off >$term <$term
    done
  fi
  # Versão apra Ubuntu com Upstart:
  # for file in /etc/init/tty*.conf; do
  #   tty="/dev/`basename $file .conf`"
  #   echo "post-start exec setterm -blank 0 -powersave off >$tty <$tty" | sudo tee -a "$file"
  # done

  #-----------------------------------------------------------------------
  # Executa arquivos no /script/boot na ordem
  ExecBootScripts

  #-----------------------------------------------------------------------
  # Reconfigura HAproxy caso haja alguma alteração pendente
  # Removido, pode fazer alguma pergunta e ficar pendente
  # . /script/info/haproxy.var
  # if [ "$HAP_NEW_CONF" == "Y" ]; then
  #   /script/haproxy.sh --reconfig
  # fi

  #-----------------------------------------------------------------------
  # Inicializa Aplicações
  # Comando de execução do SU é diferente em cada distro
  [ "$DISTRO_NAME" == "CentOS" ] && SU_C="--session-command" || SU_C="-c"
  FILES=$(ls /home/*/auto.sh)
  for f in $FILES; do
    USR=$(echo "$f" | sed 's@/home/\(.*\)/.*@\1@')
    echo "Chamando $f USR=$USR" >> /script/info/autostart.log
    # usa o su para criar um login-shell, está rodando num ambiente não padrão
    su - $USR $SU_C "nohup $f </dev/null 2>&1 >/dev/null &"
  done

fi # $CMD
