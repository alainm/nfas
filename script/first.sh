#!/bin/bash

# Script de inicialização geral, chamadao pelo boot.sh

echo "Parabéns, você está rotando o /script/first.sh"

# Altera o /etc/rc.d/rc.local para chamar o /script/autostart.sh
cat /etc/rc.d/rc.local | grep "autostart.sh"
if [ $? -ne 0 ]; then
  echo -e "\n# NFAS: executa scripts de inicialização\n/script/autostart.sh\n" >> /etc/rc.d/rc.local
fi
