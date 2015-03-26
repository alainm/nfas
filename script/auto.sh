#/bin/bash

# Script de inicialização da aplicação, chamada após o boot
# fica no /home/<user>/auto.sh
# Chamada com usuário <user>
# Não precisa retornar, chamada em Background

# ------ Inicializa e limpa log ------
echo "Rodando $HOME/auto.sh, USER=$USER"  > $HOME/auto.log
date                                     >> $HOME/auto.log
id                                       >> $HOME/auto.log
echo -e "----------\n"                   >> $HOME/auto.log

# ------ Esta parte é alterada quando é criado o aplicativo ------

# Portas para Aplicativos NODE
export NODE_PORT=3000

# ------ Fim da parte alterada automáticamente ------


