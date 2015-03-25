#/bin/bash

# Script de inicialização da aplicação, chamada após o boot
# fica no /home/<user>/auto.sh
# Chamada com usuário <user>
# Não precisa retornar, chamada em Background

# Inicializa e limpa log
echo "Rodando $HOME/auto.sh"  > $HOME/auto.log
date                         >> $HOME/auto.log

# ------ Alterada quando é criado o aplicativo ------

# Portas para Aplicativos NODE
NODE_PORT=3000

# ------ Fim da parte automática ------


