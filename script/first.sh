#!/bin/bash

# Script de inicialização geral, chamadao pelo boot.sh

echo "Parabéns, você está rotando o /script/first.sh"

# atualiza todo o sistema
yum -y update

# Diretório de dados
DADOS="/script/dados"
mkdir -p $DADOS

# Altera o /etc/rc.d/rc.local para chamar o /script/autostart.sh
cat /etc/rc.d/rc.local | grep "autostart.sh"
if [ $? -ne 0 ]; then
  echo -e "\n# NFAS: executa scripts de inicialização\n/script/autostart.sh\n" >> /etc/rc.d/rc.local
fi

# Determina se está rodando em um VirtualBox
# site: http://stackoverflow.com/questions/12874288/how-to-detect-if-the-script-is-running-on-a-virtual-machine
# A variável fica guardada no diretório de dados, para usar deve ser incluida com o camando ". "
yum install dmidecode
dmidecode  | grep -i product | grep VirtualBox
if [ $? -eq 0 ] ;then
  IS_VIRTUALBOX="Y"
else
  IS_VIRTUALBOX="N"
fi
echo "IS_VIRTUALBOX=$IS_VIRTUALBOX" > $DADOS/virtualbox
/script/virtualbox.sh

# ===== FIM do first.sh =====
# => executa o /script/autostart.sh para iniciar
/script/autostart.sh

