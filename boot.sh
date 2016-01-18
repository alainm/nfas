#!/bin/bash

# Este é o script que dá boot na instalação.
# precisa ser feito download e executado manualmente
# penas o mais básico é feito aqui

echo "Executando boot.sh, parabéns..."

# Liga modo de debug: todos os comando são mostrados no console
# set -x

# Copia repositório de scrips
# O git-clone vai criar um diretório /root/nfas/ depois copia para o /script/
# apaga o diretório nfas antes de baixar, evita que o git-clone dê erro
yum -y install git
rm -rf nfas
git clone https://github.com/alainm/nfas.git
mkdir -p /script
cp -afv nfas/script/* /script
chmod +x /script/*.sh
chmod +x /script/boot/*.sh

# Executa o /script/first.sh
cd /script
/script/first.sh
