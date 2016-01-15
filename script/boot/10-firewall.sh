#!/bin/bash
set -x

echo "Executando 10-firewall.sh" >> /script/info/autostart.log

# Carrega arquivo de configuração
[ -e /script/info/virtualbox.var ] && . /script/info/virtualbox.var

# ==================================================
# ===== ATENÇÃO: nunca altere este arquivo !!! =====
# ==================================================
# se alterar aqui e acontecer um erro, você pode ficar
#   travado para fora da sua VPS para sempre...
#
# site: http://www.cyberciti.biz/tips/linux-unix-bsd-nginx-webserver-security.html
# site: http://bash.cyberciti.biz/firewall/linux-iptables-firewall-shell-script-for-standalone-server/

#------------------------------------------------------------
# Mapa simplificado do IPTABLES (sem o mangle)
#
#                     ---------v---------
#                    | PREROUTING (dNAT) |
#                     ---------v---------
#              ----------------v----------------
#       -------v-------                         |
#      |     INPUT     |                        |
#       -------v-------                         |
#       -------v--------                 -------v------
#      | processo local |               |   FORWARD    |
#       -------v--------                 -------v------
#       -------v--------                        |
#      |    OUTPUT      |                       |
#       -------v--------                        |
#               ---------------v----------------
#                    ----------v---------
#                   | POSTROUTING (sNAT) |
#                    ----------v---------
# ATENÇÃO: No servidor só existe INPUT e OUTPUT
#------------------------------------------------------------

# precisa do iptables com path
IPT=/sbin/iptables
# Opções de LOG
LOGOPT="--log-level=3 -m limit --limit 3/minute --limit-burst 3"
# Limite para ataque tipo SYN-FLOOD
SYNOPT="-m limit --limit 5/second --limit-burst 10"
# Endereços inválidos em qualquer lugar pela RFC 3330
BADIP="0.0.0.0/8 172.16.0.0/12 255.255.255.255/32"
# Endereços Locais que não podem vir da internet, também pela RFC 3330
BADIP+=" 127.0.0.0/8 169.254.0.0/16 240.0.0.0/4 224.0.0.0/4"
# Endereços Locais que não podem vir da internet, pela RFC 2365
BADIP+=" 239.255.255.0/24"
# Endereços IP da lista negra (IPs e Redes)
BLAK_LIST=""
if [ "$IS_VIRTUALBOX" != "Y" ]; then
  BADIP+=" 10.0.0.0/8 192.168.0.0/16 172.16.0.0/16 169.254.0.0/16"
fi

#-------------------------------------------------------------------
# Limpa as regras de firewall já existentes
#-------------------------------------------------------------------
$IPT -P OUTPUT ACCEPT # Set default policy to ACCEPT
$IPT -P FORWARD DROP  # Set default policy to DROP
if [ "$OPEN_FIREWALL" == "Y" ]; then
  $IPT -P INPUT ACCEPT # Set default policy to ACCEPT: Debug
else
  $IPT -P INPUT DROP   # Set default policy to DROP: Seguro
fi
$IPT -F               # Flush all chains
$IPT -X               # Delete all chains
for table in filter nat mangle ; do
  $IPT -t $table -F   # Delete the table's rules
  $IPT -t $table -X   # Delete the table's chains
  $IPT -t $table -Z   # Zero the table's counters
done
# Não tem roteamento, então fecha roteamento pelo kernel de pacotes IPV4
echo 0 > /proc/sys/net/ipv4/ip_forward

#-------------------------------------------------------------------
# Carrega módulos necessários
#-------------------------------------------------------------------
# para fazer statefull
modprobe ip_conntrack
# para fazer regras com temporização
# modprobe ipt_recent

#---------------------------------------------------------------------
# local aceita tudo
#---------------------------------------------------------------------
$IPT -A INPUT  -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

#---------------------------------------------------------------------
# Cria CHAINS extra para tratamento de erros
#---------------------------------------------------------------------
#---------- Logga e deleta pacotes TCP com flags inválido
$IPT -N BADFLAGS
#$IPT -A BADFLAGS -j LOG --log-prefix "IPT BADFLAGS: " $LOGOPT
$IPT -A BADFLAGS -j DROP
#---------- SYN Flood Protection
# Isto é um tipo de DenialOfService: limita quantidade
# O teste tem que ser feito depois das aprovações mais genéricas
$IPT -N SYN_FLOOD
$IPT -A SYN_FLOOD -p tcp --syn $SYNOPT -j RETURN
$IPT -A SYN_FLOOD -p tcp ! --syn -j RETURN
#$IPT -A SYN_FLOOD -j LOG --log-prefix "IPT SYN_FLOOD: " $LOGOPT
$IPT -A SYN_FLOOD -j DROP
#---------- Bad IP Chain
# Logga e deleta pacotes com IP proibido
$IPT -N BAD_IP
#$IPT -A BAD_IP -j LOG --log-prefix "IPT BAD_IP: " $LOGOPT
$IPT -A BAD_IP -j DROP

#---------------------------------------------------------------------
# Proteção contra pacotes TCP com flags inválidos
#---------------------------------------------------------------------
# Valida pacotes TCP: garante que não tem FLAGs internos inválidos
#  esses inválidos são usados para furar as regras e conseguir uma
#  resposta de algum serviço
$IPT -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j BADFLAGS
$IPT -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j BADFLAGS
$IPT -A INPUT -p tcp --tcp-flags ACK,URG URG -j BADFLAGS
$IPT -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j BADFLAGS
$IPT -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j BADFLAGS
$IPT -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j BADFLAGS
$IPT -A INPUT -p tcp --tcp-flags ALL ALL -j BADFLAGS           # XMAS packets
$IPT -A INPUT -p tcp --tcp-flags ALL NONE -j BADFLAGS          # NULL packets
$IPT -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j BADFLAGS
$IPT -A INPUT -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j BADFLAGS
$IPT -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j BADFLAGS
$IPT -A INPUT -p tcp --syn -j SYN_FLOOD
# Drop sync perdido: NEW só pode ser com SYN+ACK
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -j BADFLAGS
# Drop Pacotes fragmentados
$IPT -A INPUT -f -j BADFLAGS
# elimina pacotes com broadcast/multicast: não tem em servidor
$IPT  -A INPUT -m pkttype --pkt-type broadcast -j BADFLAGS
$IPT  -A INPUT -m pkttype --pkt-type multicast -j BADFLAGS
# Elimina pacotes de um stream que se tornou inválido
$IPT  -A INPUT -m state --state INVALID -j BADFLAGS

#--------------------------------------------------------------------------
# Testes de IP na Entrada: Blacklist, Anti-spoofing
#--------------------------------------------------------------------------
# Lista negra de IPs, inválidos ou reservados pelo RFC 3330
for ip in $BADIP $BLAK_LIST
do
  $IPT -A INPUT  -s $ip -j BAD_IP
  $IPT -A OUTPUT -d $ip -j BAD_IP
done

#--------------------------------------------------------------------------
# ICMP: permite ping externo e pacotes importantes
# Outras mensagens além so echo são importantes para a administração
# tem que testar ICMP primeiro por causa do multicast do rdisc que detecta como INVALID
#--------------------------------------------------------------------------
# Ping vindo de fora é aceito: ok
$IPT -A INPUT  -p icmp --icmp-type echo-request -j ACCEPT
$IPT -A OUTPUT -p icmp --icmp-type echo-reply   -j ACCEPT
# Mensagens de erro: type=destination-unreachable" tem que aceitar na entrada (resposta)
$IPT -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
# Mensagem type=source-quench é usada para ajustar velocidade de envio
$IPT -A INPUT -p icmp --icmp-type source-quench -j ACCEPT
# Mensagem type=parameter-problem é erro no Header, ajuda a recuperar erro
$IPT -A INPUT -p icmp --icmp-type parameter-problem -j ACCEPT
# A mens. time-exceeded é importante para recuperaçõe de erros
#  mas só é permitida na entrada pois na saída permite fazer "traceroute"
$IPT -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
# Mensagens de erro: type=destination-unreachable" não aceita na saída para
#  maior segurança, a não ser code=fragmentation-needed que é nescessário
$IPT -A OUTPUT -p icmp --icmp-type fragmentation-needed -j ACCEPT
# Mensagem type=source-quench é usada para ajustar velocidade de envio
$IPT -A OUTPUT -p icmp --icmp-type source-quench -j ACCEPT
# Apagar esta mensagem atrapalha a recuperação de erro. Alguns recomendam apagar,
#  mas outros dizem que não compromete a segurança
$IPT -A OUTPUT -p icmp --icmp-type parameter-problem -j ACCEPT

#==========================================================================
# Serviços disponíveis - ENTRADAS
#==========================================================================
# Estes comandos estão em Chains separadas para poderem ser alterados
$IPT -N IN_FIREWALL
# Portas HTTP e HTTPS
$IPT -A IN_FIREWALL -p tcp --dport 80  -m state --state NEW -j ACCEPT
$IPT -A IN_FIREWALL -p tcp --dport 443 -m state --state NEW -j ACCEPT
#==========================================================================
# Chain especial para editar dinamicamente a porta do SSH
$IPT -N IN_SSH
# será configurado pelo /script/ssh.sh
#==========================================================================

#--------------------------------------------------------------------------
# Entrada do Servidor, processamento genérico
#--------------------------------------------------------------------------
# Pacotes que pertencem a conexões já estabelecidas (log só para debug)
#$IPT -A INPUT -p tcp -m state --state NEW -j LOG --log-prefix "IPT NEW IN-F @@@@: "
#$IPT -A INPUT -p tcp -m state --state RELATED -j LOG --log-prefix "IPT REL IN-F @@@@: "
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Cria uma chain para alterar dinamicamente a porta do SSH
$IPT -A INPUT -j IN_SSH
# Serviços abertos são controlados por uma outra chain
$IPT -A INPUT -j IN_FIREWALL
# Log de todo o resto
#$IPT -A INPUT -m limit --limit 5/m --limit-burst 7 -j LOG --log-prefix " DEFAULT DROP "
# Não fecha, a POLICY default já é fechada!!!
#   e assim fica possível ser alterada para usar no Virtualbox

#--------------------------------------------------------------------------
# Saída do Servidor, processamento genérico
#--------------------------------------------------------------------------
# Pacotes que pertencem a conexões já estabelecidas (log só para debug)
#$IPT -A OUTPUT -p tcp -m state --state NEW -j LOG --log-prefix "IPT NEW OUT-F @@@@: "
#$IPT -A OUTPUT -p tcp -m state --state RELATED -j LOG --log-prefix "IPT REL OUT-F @@@@: "
$IPT -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# A policy default é ACCEPT, isso facilita inserir comandos no final

#--------------------------------------------------------------------------
# Reinstala as regras do Fail2ban e porta do SSH
#--------------------------------------------------------------------------
# Centralizadas no script onde são criadas/administradas
/script/ssh.sh --firewall

#--------------------------------------------------------------------------
# Fim
#--------------------------------------------------------------------------

