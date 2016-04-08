#!/bin/bash
set -x

# Script para Armazenar Estados de Configuração do sistema.
# a principal necessidade é acessar algumas informações
#   pelo usuário (sem acesso root.
# Deve ser chamado (como root) por qualquer rotina que altere um destes parametros:
#  - SSH: acesso por senha permitido

# Os parametros levantados ficam armazenados em /script/info/state.var

ARQ=/script/info/state.var
# Funções auxiliares
. /script/functions.sh

# Lê se acesso por Senha é permitido: yes ou no
SST_SSH_PASS_AUTH=$(GetConfSpace /etc/ssh/sshd_config PasswordAuthentication)


# Grava resultados encontrados
echo "SST_SSH_PASS_AUTH=$SST_SSH_PASS_AUTH"        >$ARQ
# tem que ser acessível por usuários
chmod 644 $ARQ

