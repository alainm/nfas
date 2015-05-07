#!/bin/bash
set -x

# Script para inicializar Medição de uso da CPU e Cores
# Cria estado inicial das variáveis de uso de recursos.

# === cpu-use ===

# Le stats, seleciona linha e elimina espaços repetidos
CPU_ALL=$(sed -n '/^cpu /s/[ ]\+/ /p' /proc/stat)
# Separa compos usado para calculos
set -- $CPU_ALL                              # reset positional params (indexa apartir de 1)
IDLE=${@:5:1}                                # IDLE é posição 4 (usa +1)
ACTIVE=$(( ${@:2:1} + ${@:4:1} + ${@:6:1} )) # campos 1+3+5 (usa +1): user+system+iowait
# Guarda Valores para primeira vez
echo "PREV_IDLE=$IDLE"         >  /script/info/cpu-use.var
echo "PREV_ACTIVE=$ACTIVE"     >> /script/info/cpu-use.var

# === core-use ===

# Lê número de cores
CORES=$(grep -c ^processor /proc/cpuinfo)
# Calcula uso de cada Core
echo ""                                   >  /script/info/core-use.var
for ((N=0;N<$CORES;N++));do
  # Le stats, seleciona linha e elimina espaços repetidos
  CORE_TMP=$(sed -n "/^cpu$N /s/[ ]\+/ /p" /proc/stat)
  # Usa "parametros posicicionais" para separa campos da linha
  set -- $CORE_TMP                                  # reset positional params (indexa apartir de 1)
  IDLE_TMP=${@:5:1}                                 # IDLE é posição 4 (usa +1)
  ACTIVE_TMP=$(( ${@:2:1} + ${@:4:1} + ${@:6:1} ))  # campos 1+3+5 (usa +1): user+system+iowait
  # Guarda em novas Arrays
  echo "PREV_IDLE[$N]="$IDLE_TMP         >>  /script/info/core-use.var
  echo "PREV_ACTIVE[$N]="$ACTIVE_TMP     >> /script/info/core-use.var
done
