#!/bin/bash

# Este é o script que dá boot na instalação.
# precisa ser feito download e executado manualmente
# penas o mais básico é feito aqui

echo "Executando boot.sh, parabéns..."

# Liga modo de debug: todos os comando são mostrados no console
# set -x

# Copia repositório de scrips
# O git-clone vai criar um diretório /root/nfas/ depois copia para o /script/
yum -y install git
mkdir -p /script
rm -rf nfas
git clone https://github.com/alainm/nfas.git
cp -afv nfas/script/* /script
chmod -Rv +x /script/*.sh

# Executa o /script/first.sh
/script/first.sh
