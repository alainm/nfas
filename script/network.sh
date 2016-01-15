#!/bin/bash
set -x

# Script para as manipulações da rede
# Chamada: "/script/network.sh <cmd>"
# <cmd>: --first          durante primeira instalação
#        --ipfixo         altera para IP fixo (só no VirtualBox)
#        --monit-ifdown   quando o MONIT detectou que o LINK caiu
#        --monit-ifup     quando o MONIT detectou que o LINK voltou
#        --monit-noping   quando o MONIT detectou falha do PING

#-----------------------------------------------------------------------
# Processa a linha de comando

CMD=$1
# usa as variaveis armazenadas
. /script/info/distro.var
. /script/info/virtualbox.var
# Inclui funções básicas
. /script/functions.sh

#-----------------------------------------------------------------------
# Pergunta se altera para IP fixo, apenas no VirtualBox
# Usa todos os dados obtidos anteriormente com DHCP
function AskIpFixo(){
  local NET_ARQ=/etc/sysconfig/network-scripts/ifcfg-eth0
  NET_BOOT=$(GetConfEqual $NET_ARQ BOOTPROTO)
  [ "$NET_BOOT" != "static" ] && NET_BOOT="DHCP" || NET_BOOT="STATIC"
  NET_IP=$(GetIPv4 eth0)
  NET_MASK=$(GetMask4 eth0)
  NET_GW=$(GetGateway)
  NET_DNS=$(GetDnsServer)
      MSG=" Sua Rede está atualmente em $NET_BOOT, sua configuração é:"
    MSG+="\n   IP=$NET_IP"
    MSG+="\n   NetMask=$NET_MASK"
    MSG+="\n   Gateway=$NET_GW"
    MSG+="\n   DNS=$NET_DNS"
  MSG+="\n\nDeseja configurar como STATIC e alterar o IP?"
    MSG+="\n Obs: altera só o IP e mantém os mesmos Mask, GW e DNS"
  MSG+="\n\n(Esta opção não aparece fora do VirtualBox!)"
  # uso do whiptail: http://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail#Yes.2Fno_box
  whiptail --title "Configuração NFAS" --yesno --defaultno "$MSG" 16 78
  if [ $? -eq 0 ]; then
    # Sim:
    FIM="N"
    while [ $FIM != "Y" ]; do
         MSG="\nForneça o novo IP, a configuração abaixo será mantida:"
        MSG+="\n   NetMask=$NET_MASK"
        MSG+="\n   Gateway=$NET_GW"
        MSG+="\n   DNS=$NET_DNS"
      MSG+="\n\nSugestão de compatibilidade: altere apenas a parte final do IP"
      TMP=$(whiptail --title "Configuração NFAS" --inputbox "$MSG" 14 74 $NET_IP 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        FIM="Y"
      fi
    done # loop principal
    echo "Novo IP=$TMP"
  fi
}

#-----------------------------------------------------------------------
# Cria arquivo  que é executado ao reiniciar a rede
# http://xmodulo.com/how-to-run-startup-script-automatically-after-network-interface-is-up-on-centos.html

if [ "$CMD" == "--first" ]; then
  if [ "$DISTRO_NAME" == "CentOS" ]; then
    # só para "CentOS", deve ser o mesmo para CenOS7, Ubuntu pode ser diferente
    ARQ="/sbin/ifup-local"
    if [ ! -e $ARQ ]; then
      cat <<- EOF > $ARQ
				#!/bin/sh
				if [[ "\$1" == "eth0" ]]; then
				  echo "this part will be executed right after eth0 is up."
				  echo $(date +"[%Z %b %d %H:%M:%S]")" ifup-local: flush da fila de emails - postfix"  >> /var/log/monit.log
				  postfix flush
				  logger -t ifup-local "Postfix flush"
				fi
			EOF
      chmod +x $ARQ
    fi
  fi # CentOS

elif [ "$CMD" == "--ipfixo" ]; then
  #-----------------------------------------------------------------------
  if [ "$IS_VIRTUALBOX" == "Y" ]; then
    AskIpFixo
  fi

elif [ "$CMD" == "--monit-ifup" ]; then
  #-----------------------------------------------------------------------
  # O MONIT testa a rede a cada 60s, cai aqui quando detecta que voltou
  # verifica se tem IP
  MY_IP=$(ifconfig eth0 |GetIpFromIfconfig)
  if [ -z "$MY_IP" ]; then
    # voltou UP mas não tem IP, precisa reiniciar
    #  OBS: na prática não consegui reproduzir este cenário de maneira razoável...
    echo $(date +"[%Z %b %d %H:%M:%S]")" network.sh: perdeu IP, enviando ifup eth0"  >> /var/log/monit.log
    ifup eth0
    # já executa automáticamente /sbin/ifup-local
  else
    # testa se o PING funciona, testa 3x e só dá erro se falharem todos
    if ! ping -c 3 8.8.8.8; then
      # Se tem IP e está UP mas não tem PING: tem que reiniciar completo
      # isto acontece com: ifconfig eth0 down; <espera monit detectar>; ifconfig eth0 up
      # se fizer ifconfig eth0 down; ifconfig eth0 up o Monit não detecta e não cai aqui !!!
      echo $(date +"[%Z %b %d %H:%M:%S]")" network.sh: está UP mas sem PING, enviando ifdown/up eth0"  >> /var/log/monit.log
      ifdown eth0; ifup eth0
      # já executa automáticamente /sbin/ifup-local
    else
      # Isto acontece quando REconecta o cabo (exemplo no VirtualBox)
      # precisa enviar emails penddentes
      # mailq | grep "Mail queue is empty"; if [ $? -eq 0 ]; then echo vazia; else echo cheia; fi
      mailq | grep "Mail queue is empty"
      if [ $? -eq 0 ]; then
        echo $(date +"[%Z %b %d %H:%M:%S]")" network.sh: fila de emails já está vazia" >> /var/log/monit.log
      else
        echo $(date +"[%Z %b %d %H:%M:%S]")" network.sh: flush da fila de emails"        >> /var/log/monit.log
        postfix flush
      fi
    fi
  fi

elif [ "$CMD" == "--monit-noping" ]; then
  #-----------------------------------------------------------------------
  # O MONIT testa o Ping, cai aqui quando o ping falha
  ST=$(GetNetwokState)
  if [ "$ST" == "UN" ]; then
    # Rede está UP mas está retornando "Network is unreachable"
    # O problema é grave, precisa reiniciar a rede:
    echo $(date +"[%Z %b %d %H:%M:%S]")" network.sh: --monit-noping, Restarting eth0" >> /var/log/monit.log
    ifdown eth0; ifup eth0
  else
    echo $(date +"[%Z %b %d %H:%M:%S]")" network.sh: --monit-noping, está DOWN: não faz nada" >> /var/log/monit.log
  fi
fi
#-----------------------------------------------------------------------
