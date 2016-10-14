#/bin/bash
# set -x

# Script de inicialização da aplicação, chamada após o boot
# fica no /home/<app>/auto.sh
# Chamada com usuário <app>:
# ~/auto.sh         - Inicia a Aplicação com forever
# ~/auto.sh --stop  - para a Aplicação
# => Este escript pode ser alterado, mas com cuidado!

# ------ Inicializa e limpa log ------
echo "Rodando $HOME/auto.sh, USER=$USER"  > $HOME/auto.log
date                                     >> $HOME/auto.log
id                                       >> $HOME/auto.log
echo -e "----------\n"                   >> $HOME/auto.log

# ------ Executa o Aplicativo em loop para não abortar ------

# Mostra variáveis pré-definidas (no .bashrc)
echo "Ambiente: PORT=$PORT, ROOT_URL=$ROOT_URL"
# Elimina aplicações anteriores
echo "---------- Parando Aplicações anteriores ---------"
# Primeiro termina usando o mesmo Process Manager
# => Se alterar o método de iniciar, alterar aqui também
forever stopall
# Depois verifica se ainda tem alguma task usando a porta
PID_USING_PORT=$(fuser $PORT/tcp 2>&1 | tr -s ' ' | cut -d' ' -f2)
[ -n "$PID_USING_PORT" ] && kill $PID_USING_PORT

echo "---------- Inicianco nova Aplicação --------------"
# Testa se recebeu comando para para aplicação
if [ "$1" == "--stop" ] || [ "$1" == "stop" ]; then
  exit 0
fi

# => Altere apartir daqui o método de iniciar!
# Pasta default para Aplicação
cd ~/app
# Inicia com Forever para manter sempre no ar
forever start server.js --max-old-space-size=128

