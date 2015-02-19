#!/bin/bash

# Segundo firewall, este entra em operação após 30 segundos
# Todo o básico já está configurado, basta abrir os demais serviços

# As Chains IN_FIREWALL e OUT_FIREWALL contém todas as portas abertas
# Basta acrescentar as portas necessárias
# Estas chains podem ser apagadas e recriadas para configurações avançadas

# TODO: teste de comando para não executar, em caso de travamento

#==========================================================================
# Serviços disponíveis - ENTRADAS
#==========================================================================
# Portas HTTP
$IPT -A IN_FIREWALL -p tcp --dport 80  -m state --state NEW -j ACCEPT
$IPT -A IN_FIREWALL -p tcp --dport 443 -m state --state NEW -j ACCEPT

#==========================================================================
# Serviços acessíveis - SAIDAS
#==========================================================================
# Consulta a outros sites
$IPT -A OUT_FIREWALL -m state --state NEW -p tcp --dport 80  -j ACCEPT # http
$IPT -A OUT_FIREWALL -m state --state NEW -p tcp --dport 443 -j ACCEPT # https
