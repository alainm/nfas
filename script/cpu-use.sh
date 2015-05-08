#!/bin/bash
# set -x

# Script para Medir uso da CPU, resultado é a média de todos os cores
# Chamado pelo MONIT a cada ciclo de 60s, para avaliação
# Retorna a % de uso como errorlevel!


# Original: by Paul Colby (http://colby.id.au), no rights reserved ;)
# http://codereview.stackexchange.com/questions/62388/to-calculate-the-total-cpu-usage-as-a-percentage
# http://www.mjmwired.net/kernel/Documentation/filesystems/proc.txt#1250
#
# 0    1       2      3       4         5      6     7        8      9      10
#      user    nice   system  idle      iowait irq   softirq  steal  guest  guest_nice
# cpu  74608   2520   24433   1117073   6176   4054  0        0      0      0
# IDLE = 4
# TOTAL = 1+3+4+5 (existe discussão se deve incluir 6)

# Le dados da última execução
. /script/info/cpu-use.var

# Le stats, seleciona linha e elimina espaços repetidos
CPU_ALL=$(sed -n '/^cpu /s/[ ]\+/ /p' /proc/stat)

# Separa compos usado para calculos
set -- $CPU_ALL                              # reset positional params (indexa apartir de 1)
IDLE=${@:5:1}                                # IDLE é posição 4 (usa +1)
ACTIVE=$(( ${@:2:1} + ${@:4:1} + ${@:6:1} )) # campos 1+3+5 (usa +1): user+system+iowait
# Calcula as diferenças e uso total
DIFF_IDLE=$(( $IDLE - $PREV_IDLE ))
DIFF_ACTIVE=$(( $ACTIVE - $PREV_ACTIVE ))
CPU_USE=$(( $DIFF_ACTIVE * 100 / ( $DIFF_ACTIVE + $DIFF_IDLE ) ))
# Faz a conta com uma casa decimal e coloca um "0" na frente
CPU_USE_F=$(echo "scale=1; $DIFF_ACTIVE * 100 / ( $DIFF_ACTIVE + $DIFF_IDLE )" | bc)
[ "${CPU_USE_F:0:1}" == "." ] && CPU_USE_F="0$CPU_USE_F"
echo "Uso total de CPU=$CPU_USE_F% (media de um minuto)"

# Guarda Valores para próxima vez
echo "PREV_IDLE=$IDLE"         >  /script/info/cpu-use.var
echo "PREV_ACTIVE=$ACTIVE"     >> /script/info/cpu-use.var

# Retorna uso total da CPU como errorlevel
exit $CPU_USE
