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
# Arquivo de Informação gerado
VAR_FILE=/script/info/network.var
# Lê dados anteriores, se existirem
[ -e $VAR_FILE ] && . $VAR_FILE
# usa as variaveis armazenadas
. /script/info/network.var
. /script/info/distro.var
. /script/info/virtualbox.var
# Inclui funções básicas
. /script/functions.sh

#-----------------------------------------------------------------------
# Pergunta se altera para IP fixo, apenas no VirtualBox
# Usa todos os dados obtidos anteriormente com DHCP
function AskIpFixo(){
  local IP_TMP IP_OK IP_ABORT IP_FIM MSG ERR_ST
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
  if [ $? -ne 0 ]; then
    exit 0
  fi

  # Sim: Vai alterar IP
  IP_OK="N"; IP_ABORT="N"; ERR_ST=""
  while [ "$IP_OK" != "Y" ]; do
    IP_TMP="$NET_IP"
       MSG="\nForneça o novo IP, a configuração abaixo será mantida:"
      MSG+="\n   NetMask=$NET_MASK"
      MSG+="\n   Gateway=$NET_GW"
      MSG+="\n   DNS=$NET_DNS"
    MSG+="\n\nSugestão de compatibilidade: altere apenas a parte final do IP"
    MSG+="\n\n$ERR_ST"
    IP_TMP=$(whiptail --title "Configuração NFAS" --inputbox "$MSG" 16 74 $IP_TMP 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      exit 0
    fi
    echo "Novo IP=$IP_TMP"
    # Verifica se IP é válido usando ipcalc
    ipcalc -c $IP_TMP
    if [ $? -ne 0 ]; then
      ERR_ST="IP é inválido, por vafor tente novamente"
      continue
    fi
    # Usando ipcalc calcula o endereço de rede dos IPs velho e novo, tem que ser igual
    local TMP1=$(ipcalc -n $NET_IP $NET_MASK)
    local TMP2=$(ipcalc -n $IP_TMP $NET_MASK)
    if [ "$TMP1" != "$TMP2" ]; then
      ERR_ST="IP fornecido não pertence à MESMA REDE, por vafor tente novamente"
      continue
    fi
    NET_IP=$IP_TMP
    echo "Novo IP=$IP_TMP"
    if [ "$DISTRO_NAME" == "CentOS" ]; then
      # Atualiza IP no arquivo de configuração: /etc/sysconfig/network-scripts/ifcfg-eth0
      EditConfEqualSafe $NET_ARQ BOOTPROTO static
      EditConfEqualSafe $NET_ARQ IPADDR $NET_IP
      EditConfEqualSafe $NET_ARQ NETMASK $NET_MASK
      # Atualiza IP no arquivo de configuração: /etc/sysconfig/network
      EditConfEqualSafe /etc/sysconfig/network GATEWAY $NET_GW
    else
      # os arquivos de configuração do Ubuntu são outros
      echo "Ubuntu não implementado"
    fi
    # Prepara para Reboot: Salva vatiáveis
    NEW_IP_CONTINUE="Y"
    SaveNetVars
    # Avisa que vai rebootar
       MSG="\n O Sistema precisa rebootar com o NOVO IP..."
    MSG+="\n\n Aguarde o fim da inicialização e conecte novamente."
      MSG+="\n   A instalação vai continuar automáticamente."
    whiptail --title "Instalação NFAS" --msgbox "$MSG" 12 60
    # Mensagem no terminal após desconexão
    set +x
    echo -e "\n         ┌──────────────────────────────────────────────┐"
    echo -e   "         │         A VM vai rebootar, aguarde...        │"
    echo -e   "         │                                              │"
    echo -e   "         │           Reconecte com O NOVO IP            │"
    echo -e   "         │          para continuar a instalação         │"
    echo -e   "         └──────────────────────────────────────────────┘\n"
    # Determina o PID desta conexão do SSHD
    PID_SSH=$(ps aux | grep "ssh" | grep "@${SSH_TTY:5}" |  awk '{print $2}')
    # Executa sem interrupsão após desconectar
    nohup bash -c "kill $PID_SSH; reboot" &> /dev/null < /dev/null &
    # Encerra execução do script, o reboot roda em segundo plano!
    exit 1
    IP_OK="Y"
  done #IP_OK
}

#-----------------------------------------------------------------------
# Salva variáveis de informações coletadas, outros pacotes vão utilizar
function SaveNetVars(){
  # Verifica se variáveis existem, só a primeira é garantida
  [ -z "$NET_IP" ] && NET_IP="DHCP"
  [ -z "$NEW_IP_CONTINUE" ] && NEW_IP_CONTINUE="N"
  echo "NET_IP=$NET_IP"                            2>/dev/null >  $VAR_FILE
  echo "NEW_IP_CONTINUE=$NEW_IP_CONTINUE"          2>/dev/null >> $VAR_FILE
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
