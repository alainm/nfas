#!/bin/bash
set -x

# Script para Instalar e Configurar o HAprozy
# Uso: /script/haproxy.sh <cmd>
# <cmd>: --first       primeira instalação

# Instalando o Haproxy do fonte
# @author original Marcos de Lima Carlos, adaptado por Alain Mouette
# Opções do HAproxy: "TARGET=linux2628", esta é a opção de otimização mais nova
#   para verificar se existe uma nova, use o make sem parametros:
#   cd /script/install/haproxy-1.6.3; make; cd

# Sites de DownLoad do HAproxy e Lua da versão aprovada
HAPROXY_DL="http://www.haproxy.org/download/1.6/src"
LUA_DL="http://www.lua.org/ftp"
INSTALL_DIR="/script/install"

#=======================================================================
# Processa a linha de comando
CMD=$1
# Lê dados anteriores se existirem
. /script/info/distro.var
. /script/info/email.var
VAR_FILE="/script/info/haproxy.var"
[ -e $VAR_FILE ] && . $VAR_FILE

#-----------------------------------------------------------------------
# Fornece a versão do HAproxy 1.6 mais novo
# http://www.lua.org/manual/
function GetVerHaproxy(){
  # usa o WGET com "--no-dns-cache -4" para melhorar a velocidade de conexão
  local SRC=$(wget --quiet --no-dns-cache -4 $HAPROXY_DL/ -O - | \
              sed -n 's/.*\(haproxy-1\.6\.[0-9]\+\)\.tar\.gz<.*/\1/p' | sort | tail -n 1)
  echo "$SRC"
}

#-----------------------------------------------------------------------
# Fornece a versão do HAproxy 1.6 mais novo
function GetVerLua(){
  # usa o WGET com "--no-dns-cache -4" para melhorar a velocidade de conexão
  local SRC=$(wget --quiet --no-dns-cache -4 $LUA_DL/ -O - | \
              sed -n 's/.*\(lua-5\.3\.[0-9]\+\)\.tar\.gz<.*/\1/p' | sort | tail -n 1)
  echo "$SRC"
}

#-----------------------------------------------------------------------
# Instala HAproxy 1.6 com LUA
# http://blog.haproxy.com/2015/10/14/whats-new-in-haproxy-1-6/
function HaproxyInstall(){
  #cria o diretórios de instalação
  mkdir -p  $INSTALL_DIR
  pushd $INSTALL_DIR

  # Carrega última versão do Lua 5.3
  HAPROXY_LUA_VER=$(GetVerLua)
  rm -f $HAPROXY_LUA_VER.tar.gz
  wget $LUA_DL/$HAPROXY_LUA_VER.tar.gz
  tar xf $HAPROXY_LUA_VER.tar.gz
  cd $HAPROXY_LUA_VER
  make linux
  make install
  cd $INSTALL_DIR

  # Carrega última versão do HAproxy 1.6
  HAPROXY_VER=$(GetVerHaproxy)
  #efetua o download e descompacta
  rm -f $HAPROXY_VER.tar.gz
  wget $HAPROXY_DL/$HAPROXY_VER.tar.gz
  tar xf $HAPROXY_VER.tar.gz
  cd $HAPROXY_VER
  make TARGET=linux2628 CPU=x8664 USEOPENSSL=1 USEZLIB=1 USEPCRE=1 USELUA=yes LDFLAGS=-ldl
  make install
  # Cria um link, alguns scripts usam o binário no /usr/sbin
  ln -sf /usr/local/sbin/haproxy /usr/sbin/haproxy

  # adiciona o usuário do haproxy
  id -u haproxy &>/dev/null || useradd -s /usr/sbin/nologin -r haproxy
  # copia o init.d e dá permissão de execução (usa mesma dos outros arquivos).
  # TODO: usar uptart/systemd CentOS/Ubuntu, testar $DISTRO_NAME
  cp examples/haproxy.init /etc/init.d/haproxy
  chmod 755 /etc/init.d/haproxy
  # copia os arquivos de erro
  mkdir -p /etc/haproxy/error
  cp examples/errorfiles/* /etc/haproxy/error
  chmod 600 /etc/haproxy/error
  # cria os diretórios em etc e stats.
  mkdir -p /var/lib/haproxy
  touch /var/lib/haproxy/stats
  # TODO: precisa do logrotate ?????????????

  # Volta e remove diretório temporário
  popd
  # rm -rf $INSTALL_DIR
}

#=======================================================================
# main()

TITLE="NFAS - Configuração do HAproxy"
if [ "$CMD" == "--first" ]; then
  # Instala HAproxy, não configura nem inicializa
  HaproxyInstall

fi
#=======================================================================
