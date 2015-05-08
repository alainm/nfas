#!/bin/bash
# set -x

# http://codereview.stackexchange.com/questions/62388/to-calculate-the-total-cpu-usage-as-a-percentage
# http://www.mjmwired.net/kernel/Documentation/filesystems/proc.txt#1250
# 0    1       2      3       4         5      6     7        8      9      10
#      user    nice   system  idle      iowait irq   softirq  steal  guest  guest_nice
# cpu  74608   2520   24433   1117073   6176   4054  0        0      0      0
# IDLE = 4
# TOTAL = 1+3+4+5 (existe discussão se inclui 6)

# Le dados da última execução
. /script/info/core-use.var

# Lê número de cores
CORES=$(grep -c ^processor /proc/cpuinfo)

# Le stats, seleciona linha e elimina espaços repetidos
for ((N=0;N<$CORES;N++));do
  CORE[$N]=$(sed -n "/^cpu$N /s/[ ]\+/ /p" /proc/stat)
done

# Calcula uso de cada Core
MAX=0
MAX_F=0.0
for ((N=0;N<$CORES;N++));do
  CORE_TMP=${CORE[N]}
  set -- $CORE_TMP                                  # reset positional params (indexa apartir de 1)
  IDLE_TMP=${@:5:1}                                # IDLE é posição 4 (usa +1)
  ACTIVE_TMP=$(( ${@:2:1} + ${@:4:1} + ${@:6:1} )) # campos 1+3+5 (usa +1): user+system+iowait
  # Pega valores anteriores
  PREV_IDLE_TMP=${PREV_IDLE[N]}
  PREV_ACTIVE_TMP=${PREV_ACTIVE[N]}
  [ -z "$PREV_IDLE_TMP"  ] && PREV_IDLE_TMP=0
  [ -z "$PREV_ACTIVE_TMP" ] && PREV_ACTIVE_TMP=0
  # Calcula as diferenças e uso total
  DIFF_IDLE=$(( $IDLE_TMP - $PREV_IDLE_TMP ))
  DIFF_ACTIVE=$(( $ACTIVE_TMP - $PREV_ACTIVE_TMP ))
  CORE_USE_TMP=$(( $DIFF_ACTIVE * 100 / ( $DIFF_ACTIVE + $DIFF_IDLE ) ))
  # Faz a conta com uma casa decimal e coloca um "0" na frente
  CORE_USE_TMP_F=$(echo "scale=1; $DIFF_ACTIVE * 100 / ( $DIFF_ACTIVE + $DIFF_IDLE )" | bc)
  [ "${CORE_USE_TMP_F:0:1}" == "." ] && CORE_USE_TMP_F="0$CORE_USE_TMP_F"
  # Guarda em novas Arrays
  IDLE[$N]=$IDLE_TMP
  ACTIVE[$N]=$ACTIVE_TMP
  CORE_USE[$N]=$CORE_USE_TMP
  # Calcula Core com maior uso
  if [ $CORE_USE_TMP -gt $MAX ]; then
    MAX=$CORE_USE_TMP
    MAX_F=$CORE_USE_TMP_F
  fi
done

echo "CORE com maior uso=$MAX_F% (media de um minuto)"

# # Guarda Valores para próxima vez
echo ""                                   >  /script/info/core-use.var
for ((N=0;N<$CORES;N++));do
  echo "PREV_IDLE[$N]="${IDLE[N]}         >>  /script/info/core-use.var
  echo "PREV_ACTIVE[$N]="${ACTIVE[N]}     >> /script/info/core-use.var
done

# Retorna uso máximo de CORE como errorlevel
# Se tem só um core, reporta sempre ZERO para não gerar alerta repetido
if [ $CORES -eq 1 ]; then
  exit 0
else
  exit $CORE_USE
fi
