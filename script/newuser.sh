#!/bin/bash
set -x

# Script para criar um novo usuário

# >>>> PROVISÓRIO <<<<
# necessário apenas para testar os outros recursos

# criando usuários
# OBS: --stdin só funciona no CentOS (não no Ubuntu 14.04)
# OBS: useradd não cria o home directory no Ubuntu 14.04, só com "-m"
useradd teste1
echo "node1" | passwd --stdin teste1
cp -a /script/auto.sh /home/teste1
chown teste1:teste1 /home/teste1/auto.sh

useradd teste2
echo "node2" | passwd --stdin teste2
cp -a /script/auto.sh /home/teste2
chown teste2:teste2 /home/teste2/auto.sh
sed -i 's/\(export NODE_PORT=\).*/\13010/' /home/teste2/auto.sh

