#/bin/bash
# set -x

# Script de inicialização da aplicação, chamada após o boot
# fica no /home/<user>/auto.sh
# Chamada com usuário <user>
# Não precisa retornar, chamada em Background

# ------ Inicializa e limpa log ------
echo "Rodando $HOME/auto.sh, USER=$USER"  > $HOME/auto.log
date                                     >> $HOME/auto.log
id                                       >> $HOME/auto.log
echo -e "----------\n"                   >> $HOME/auto.log

# ------ Executa o Aplicativo em loop para não abortar ------

# Mostra variáveis pré-definidas (no .bashrc)
echo "Ambiente: NODE_PORT=$NODE_PORT, PORT=$PORT, NODE_URI=$NODE_URI"

# Pasta default para Aplicação
cd ~/app
# Inicia com Forever para manter sempre no ar
forever start server.js

