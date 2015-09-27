#!/bin/bash
set -x

# Script para inicializar o NTPD

# Problema: O NTPD não faz o ajuste se o erro for muito grande
#   e pode (?) abortar o serviço

# Problema2: o comando "ntpd -q -g" pode piorar o relógio se já estiver ok...


