#!/bin/bash
set -x

# Script para Instalar e Configurar o HAprozy
# Uso: /script/haproxy.sh <cmd>
# <cmd>: --first       primeira instalação
# <cmd>: --app <user>  altera configuração da Aplicação

# Instalando o Haproxy do fonte
# @author original Marcos de Lima Carlos, adaptado por Alain Mouette
# Opções do HAproxy: "TARGET=linux2628", esta é a opção de otimização mais nova
#   para verificar se existe uma nova, use o make sem parametros:
#   cd /script/install/haproxy-1.6.3; make; cd

# Sites de DownLoad do HAproxy e Lua da versão aprovada
HAPROXY_DL="http://www.haproxy.org/download/1.6/src"
LUA_DL="http://www.lua.org/ftp"
INSTALL_DIR="/script/install"

#-----------------------------------------------------------------------
# Strings de configuração do HAproxy
# Configurações de: https://mozilla.github.io/server-side-tls/ssl-config-generator/
#   e https://wiki.mozilla.org/Security/Server_Side_TLS#Recommended_configurations
#
# Nível 1: MODERNO
   HAP_GLOBAL_N1="  # set default parameters to the modern configuration"
HAP_GLOBAL_N1+="\n  tune.ssl.default-dh-param 2048"
HAP_GLOBAL_N1+="\n  ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK"
    HAP_HTTPS_N1="  bind  :443 no-sslv3 no-tlsv10 crt /etc/haproxy/certs"
# Nível 2: INTERMEDIARIO
   HAP_GLOBAL_N2="  # set default parameters to the intermediate configuration"
HAP_GLOBAL_N2+="\n  tune.ssl.default-dh-param 2048"
HAP_GLOBAL_N2+="\n  ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"
    HAP_HTTPS_N2="  bind  :443 ssl no-sslv3 crt /etc/haproxy/certs"
# Nível 3: ANTIGO
   HAP_GLOBAL_N3="  # set default parameters to the old configuration"
HAP_GLOBAL_N3+="\n  tune.ssl.default-dh-param 1024"
HAP_GLOBAL_N3+="\n  ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"
    HAP_HTTPS_N3="  bind  :443 ssl crt /etc/haproxy/certs"

#=======================================================================
# Processa a linha de comando
CMD=$1
HAPP=$2
# Lê dados anteriores se existirem
. /script/info/distro.var
. /script/info/email.var
VAR_FILE="/script/info/haproxy.var"
[ -e $VAR_FILE ] && . $VAR_FILE
TITLE="NFAS - Configuração do HAproxy"

#-----------------------------------------------------------------------
# Pergunta nível de Segurança do HAproxy
# Nível atual em HAP_CRYPT_LEVEL
function GetHaproxyLevel(){
  local MENU_IT, MSG;
  while true; do
    if [ "$CMD" == "--first" ]; then
      MSG="\nQual o Nível de Segurança de Criptografia para o Servidor:"
    else
      MSG="\nQual o Nível de Segurança de Criptografia (ATUAL=$HAP_CRYPT_LEVEL)"
    fi

    MENU_IT=$(whiptail --title "$TITLE" \
      --menu "$MSG" --fb 20 76 3   \
      "1" "Moderno - Comunicação segura, só Browsers novos (nível A+)"  \
      "2" "Intermediário - Compatibilidade, aceita a maioria dos Browsers" \
      "3" "Antigo - Baixa Segurança, WinXP e IE6"             \
      3>&1 1>&2 2>&3)
    if [ $? == 0 ]; then
      HAP_CRYPT_LEVEL=$MENU_IT
      echo $MENU_IT
      return 0
    fi
  done
}

#-----------------------------------------------------------------------
# Lê dados de uma APP se existirem
# Usa a variável $HAPP para identificar
function GetSingleAppVars(){
  local APP_FILE="/script/info/hap-$HAPP.var"
  # Apaga variáveis anteriores e gera compatibilidade
  HAPP_HTTP="Y"
  HAPP_HTTPS="N"
  HAPP_URIS=""
  HAPP_INIT=""
  if [ -e $APP_FILE ]; then
    # Lê arquivo já existente
    . $APP_FILE
  fi
}

#-----------------------------------------------------------------------
# Salve dados de uma APP
# Usa a variável $HAPP para identificar
function SaveSingleAppVars(){
  local APP_FILE="/script/info/hap-$HAPP.var"
  echo "HAPP_HTTP=\"$HAPP_HTTP\""                    2>/dev/null >  $APP_FILE
  echo "HAPP_HTTPS=\"$HAPP_HTTPS\""                  2>/dev/null >> $APP_FILE
  echo "HAPP_URIS=\"$HAPP_URIS\""                    2>/dev/null >> $APP_FILE
  echo "HAPP_INIT=\"Y\""                             2>/dev/null >> $APP_FILE
}

#-----------------------------------------------------------------------
# Pergunta Nível de Conexão Segura de uma Aplicação
# HTTP e/ou HTTPS
# Retorna: 0=alteração completada, 1=cancelada
function GetAppConnType(){
  local DEF_OPT,MSG,MENU_IT
   MSG="\nSelecione o tipo de Conexão para o seu Aplicativo."
  MSG+="\nOs certificados serão providenciados automáticamente"
  MSG+="\n usando o Let's Encrypt."
  if [ "$HAPP_INIT" != "Y" ]; then
    DEF_OPT="Só HTTPS"
    MSG+="\n\n"
  else
    if [ "$HAPP_HTTP" != "Y" ] &&  [ "$HAPP_HTTPS" == "Y" ]; then
      DEF_OPT="Só HTTPS"
    elif [ "$HAPP_HTTP" == "Y" ] &&  [ "$HAPP_HTTPS" == "Y" ]; then
      DEF_OPT="Ambos"
    else
      DEF_OPT="Só HTTP"
    fi
    MSG+="\n\n Sua opção atual é $DEF_OPT"
  fi
  MENU_IT=$(whiptail --title "$TITLE"                                \
    --menu "$MSG" --default-item "$DEF_OPT" --fb 20 70 3             \
    "Só HTTPS" "  Só aceita conexão SEGURA (HTTP será redirecionado)"  \
    "Ambos"    "  Implementa ambos e não redireciona"                  \
    "Só HTTP"  "  Só implementa HTTP simples (só para testes)"         \
    3>&1 1>&2 2>&3)
  if [ $? != 0 ]; then
    echo "Seleção cancelada."
    exit 1
  fi

  # Interpreta Opções
  if [ "$MENU_IT" == "Só HTTPS" ];then
    HAPP_HTTP="N"
    HAPP_HTTPS="Y"
  elif [ "$MENU_IT" == "Ambos" ];then
    HAPP_HTTP="Y"
    HAPP_HTTPS="Y"
  else
    HAPP_HTTP="Y"
    HAPP_HTTPS="N"
  fi
  return 0
}

#-----------------------------------------------------------------------
# Pergunta os Domínios e URI de uma Aplicação
# Aceita lista, mostra anterior para alterar
# Retorna: 0=alteração completada, 1=cancelada
function GetAppUriList(){
  return 0
}

#-----------------------------------------------------------------------
# Pergunta quantos Workers para esta aplicação
# Retorna: 0=alteração completada, 1=cancelada
function GetWorkersNum(){
  return 0
}

#-----------------------------------------------------------------------
# Edita Configurações de uma App
# Retorna: 0=alteração completada, 1=cancelada
function EditAppConfig(){
  # Lê dados desta aplicação, se existirem
  GetSingleAppVars
  # Pergunta tipo de Conexão
  GetAppConnType
  [ $? -ne 0 ] && return 1
  # Pergunta
  GetAppUriList
  [ $? -ne 0 ] && return 1
  # Pergunta número de workers
  GetWorkersNum
  [ $? -ne 0 ] && return 1
  # foi confirmado, calva configuração a Aplicação
  SaveSingleAppVars
}

#=======================================================================
# Fornece a versão do HAproxy 1.6 mais novo
# http://www.lua.org/manual/
function GetVerHaproxy(){
  # usa o WGET com "--no-dns-cache -4" para melhorar a velocidade de conexão
  local SRC=$(wget --quiet --no-dns-cache -4 $HAPROXY_DL/ -O - | \
              sed -n 's/.*\(haproxy-1\.6\.[0-9]\+\)\.tar\.gz<.*/\1/p' | sort | tail -n 1)
  echo "$SRC"
}

#-----------------------------------------------------------------------
# Fornece a versão do Lua 5.3 mais novo
function GetVerLua(){
  # usa o WGET com "--no-dns-cache -4" para melhorar a velocidade de conexão
  local SRC=$(wget --quiet --no-dns-cache -4 $LUA_DL/ -O - | \
              sed -n 's/.*\(lua-5\.3\.[0-9]\+\)\.tar\.gz<.*/\1/p' | sort | tail -n 1)
  echo "$SRC"
}

#-----------------------------------------------------------------------
# Instala HAproxy 1.6 com LUA
# http://blog.haproxy.com/2015/10/14/whats-new-in-haproxy-1-6/
# Verifica opções de compilação: http://stackoverflow.com/questions/34986893/getting-error-as-unknown-keyword-ssl-in-haproxy-configuration-file
  # $ haproxy -vv
  # HA-Proxy version 1.6.3 2015/12/25
  # [...]
  # Built with OpenSSL version : OpenSSL 1.0.1e 11 Feb 2013
  # Running on OpenSSL version : OpenSSL 1.0.1e 11 Feb 2013
  # OpenSSL library supports TLS extensions : yes
  # OpenSSL library supports SNI : yes
  # OpenSSL library supports prefer-server-ciphers : yes
  # [...]

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
  make TARGET=linux2628 CPU=x8664 USE_OPENSSL=1 USE_ZLIB=1 USE_PCRE=1 USE_LUA=yes LDFLAGS=-ldl
  make install
  # Verifica compilação e opções
  ./haproxy -vv > /root/haproxy.opt.txt
  # Cria um link, alguns scripts usam o binário no /usr/sbin
  ln -sf /usr/local/sbin/haproxy /usr/sbin/haproxy

  # adiciona o usuário do haproxy
  id -u haproxy &>/dev/null || useradd -s /usr/sbin/nologin -r haproxy
  # copia o init.d e dá permissão de execução (usa mesma dos outros arquivos).
  # TODO: usar uptart/systemd CentOS/Ubuntu, testar $DISTRO_NAME
  cp examples/haproxy.init /etc/init.d/haproxy
  chmod 755 /etc/init.d/haproxy
  # copia os arquivos de erro
  mkdir -p /etc/haproxy/errors
  cp examples/errorfiles/* /etc/haproxy/errors
  chmod 600 /etc/haproxy/errors
  # cria os diretórios em etc e stats.
  mkdir -p /var/lib/haproxy
  touch /var/lib/haproxy/stats
  # TODO: precisa do logrotate ????????????? => sim

  # Volta e remove diretório temporário
  popd
  rm -rf $INSTALL_DIR
}

#-----------------------------------------------------------------------
# Configura o HAproxy
# Configurações de: https://mozilla.github.io/server-side-tls/ssl-config-generator/
function HaproxyConfig(){
	local ARQ
  # Le o nível de segurança desejado, fica no $HAP_CRYPT_LEVEL
  GetHaproxyLevel

# Provisório: sem SSL
HAP_WITH_SSL="N"

  ARQ="/etc/haproxy/haproxy.cfg"
  if [ ! -e $ARQ ]; then
    echo "##################################################"               >  $ARQ
    echo "##  HAPROXY: arquivo de configuração principal"                   >> $ARQ
    echo "##################################################"               >> $ARQ
    echo "##  Depois de criado, apenas a linha identificadas são alteradas" >> $ARQ
    echo "##  @author original: Marcos de Lima Carlos"                      >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "global"                                                           >> $ARQ
    echo "  maxconn 20000"                                                  >> $ARQ
    echo "  #{NFAS-Cfg-Ini}"                                                >> $ARQ
    if [ "$HAP_CRYPT_LEVEL" == "1" ]; then
      echo -e "$HAP_GLOBAL_N1"                                              >> $ARQ
    elif [ "$HAP_CRYPT_LEVEL" == "3" ]; then
      echo -e "$HAP_GLOBAL_N3"                                              >> $ARQ
    else
      # default é nível Intermediário
      echo -e "$HAP_GLOBAL_N2"                                              >> $ARQ
    fi
    echo "  #{NFAS-Cfg-Fim}"                                                >> $ARQ
    echo "  ssl-default-bind-options no-tls-tickets"                        >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "defaults"                                                         >> $ARQ
    echo "  mode http"                                                      >> $ARQ
    echo "  option forwardfor"                                              >> $ARQ
    echo "  option http-server-close"                                       >> $ARQ
    echo "  timeout connect 5000ms"                                         >> $ARQ
    echo "  timeout client 50000ms"                                         >> $ARQ
    echo "  timeout server 50000ms"                                         >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "  errorfile 400 /etc/haproxy/errors/400.http"                     >> $ARQ
    echo "  errorfile 403 /etc/haproxy/errors/403.http"                     >> $ARQ
    echo "  errorfile 408 /etc/haproxy/errors/408.http"                     >> $ARQ
    echo "  errorfile 500 /etc/haproxy/errors/500.http"                     >> $ARQ
    echo "  errorfile 502 /etc/haproxy/errors/502.http"                     >> $ARQ
    echo "  errorfile 503 /etc/haproxy/errors/503.http"                     >> $ARQ
    echo "  errorfile 504 /etc/haproxy/errors/504.http"                     >> $ARQ
    echo ""                                                                 >> $ARQ
#     echo "include config/*.cfg"                                             >> $ARQ
#     echo "include backend/*.cfg"                                            >> $ARQ
  fi

#   ARQ="/etc/haproxy/http.cfg"
#   if [ ! -e $ARQ ]; then
#     echo "##################################################"               >  $ARQ
#     echo "##  HAPROXY: configuração do HTTP"                                >> $ARQ
#     echo "##################################################"               >> $ARQ
#     echo "##  Depois de criado, apenas a linha identificadas são alteradas" >> $ARQ
#     echo "##  @author original: Marcos de Lima Carlos"                      >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "frontend www-http"                                                >> $ARQ
    echo "  bind :80"                                                       >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "  #{NFAS-Cfg-Ini}"                                                >> $ARQ
    echo "  #{NFAS-Cfg-Fim}"                                                >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "  default_backend http-backend"                                   >> $ARQ
#   fi

    if [ "$HAP_WITH_SSL" == "Y" ]; then
#   ARQ="/etc/haproxy/https.cfg"
#   if [ ! -e $ARQ ]; then
#     echo "##################################################"               >  $ARQ
#     echo "##  HAPROXY: configuração do HTTPS"                               >> $ARQ
#     echo "##################################################"               >> $ARQ
#     echo "##  Depois de criado, apenas a linha identificadas são alteradas" >> $ARQ
#     echo "##  @author original: Marcos de Lima Carlos"                      >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "frontend www-https"                                               >> $ARQ
    echo ""                                                                 >> $ARQ
    if [ "$HAP_CRYPT_LEVEL" == "1" ]; then
      echo -e "$HAP_HTTPS_N1"                                               >> $ARQ
    elif [ "$HAP_CRYPT_LEVEL" == "3" ]; then
      echo -e "$HAP_HTTPS_N3"                                               >> $ARQ
    else
      # default é nível Intermediário
      echo -e "$HAP_HTTPS_N2"                                               >> $ARQ
    fi
    echo "  tcp-request inspect-delay 5s"                                   >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "  tcp-request content accept if { req_ssl_hello_type 1 }"         >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "  rspadd  Strict-Transport-Security:\ max-age=15768000 # pesquisar" >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "  #{NFAS-Cfg-Ini}"                                                >> $ARQ
    echo "  #{NFAS-Cfg-Fim}"                                                >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "  default_backend http-backend"                                   >> $ARQ
#   fi
  fi

#   ARQ="/etc/haproxy/backend/http-default.cfg"
#   mkdir -p /etc/haproxy/backend
#   if [ ! -e $ARQ ]; then
#     echo "##################################################"               >  $ARQ
#     echo "##  HAPROXY: backend default"                                     >> $ARQ
#     echo "##################################################"               >> $ARQ
#     echo "##  Depois de criado, não é mais alterado" >> $ARQ
#     echo "##  @author original: Marcos de Lima Carlos"                      >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "backend http-backend"                                             >> $ARQ
    if [ "$HAP_WITH_SSL" == "Y" ]; then
      echo "    redirect scheme https if !{ ssl_fc }"                       >> $ARQ
    fi
#   fi

  # Verifica arquivo de configuração
  haproxy -c -q -V -f /etc/haproxy/haproxy.cfg
  # instala ou restart serviço
  if [ "$CMD" == "--first" ]; then
    chkconfig --add haproxy
    service haproxy start
  else
    service haproxy restart
  fi
}

#-----------------------------------------------------------------------
# Salva variáveis de configuração
# Neste módulo as variáveis são usadas sempre apartir do arquivo de configuração Real
# Estas variáveis são guardadas apenas para recurso futuro de exportação
function SaveHaproxyVars(){
  echo "HAP_CRYPT_LEVEL=\"$HAP_CRYPT_LEVEL\""                         2>/dev/null >  $VAR_FILE
}


#=======================================================================
# main()

if [ "$CMD" == "--first" ]; then
  # Instala HAproxy, não configura nem inicializa
#   HaproxyInstall
# ==>> Provisório, só testes
rm -f /etc/haproxy/haproxy.cfg
  HaproxyConfig

elif [ "$CMD" == "--app" ]; then
  #-----------------------------------------------------------------------
  # Lê Configurações para aquela App
  EditAppConfig

fi

# Salva Variáveis alteradas
SaveHaproxyVars

#=======================================================================
