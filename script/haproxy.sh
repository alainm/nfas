#!/bin/bash
set -x

# Script para Instalar e Configurar o HAprozy
# Uso: /script/haproxy.sh <cmd>
# <cmd>: --first       primeira instalação
# <cmd>: --app <user>  altera configuração da Aplicação
# <cmd>: --reconfig    Reconfigura se alguma coisa mudou

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

#-----------------------------------------------------------------------
# Pergunta nível de Segurança do HAproxy
# Nível atual em HAP_CRYPT_LEVEL
function GetHaproxyLevel(){
  local MENU_IT, MSG;
  if [ "$CMD" == "--first" ]; then
    MSG="\nQual o Nível de Segurança de Criptografia para o Servidor:"
  else
    MSG="\nQual o Nível de Segurança de Criptografia (ATUAL=$HAP_CRYPT_LEVEL)"
  fi

  MENU_IT=$(whiptail --title "$TITLE" --nocancel                         \
    --menu "$MSG" --fb 20 76 3                                           \
    "1" "Moderno - Comunicação segura, só Browsers novos (nível A+)"     \
    "2" "Intermediário - Compatibilidade, aceita a maioria dos Browsers" \
    "3" "Antigo - Baixa Segurança, WinXP e IE6"                          \
    3>&1 1>&2 2>&3)
  HAP_CRYPT_LEVEL=$MENU_IT
  echo $MENU_IT
  return 0
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
  HAPP_PORT=""
  if [ -e $APP_FILE ]; then
    # Lê arquivo já existente
    . $APP_FILE
  fi
}

#-----------------------------------------------------------------------
# Salve dados de uma APP
# Usa a variável $HAPP para identificar
function ConfigSingleApp(){
  local APP_FILE="/script/info/hap-$HAPP.var"
  # Se não tinha PORT atribuida, usa a próxima e recalcula
  if [ -z "$HAPP_PORT" ]; then
    HAPP_PORT=$HAP_NXT_PORT
    HAP_NXT_PORT=$(( $HAP_NXT_PORT + 100 ))
  fi
  echo "HAPP_HTTP=\"$HAPP_HTTP\""                    2>/dev/null >  $APP_FILE
  echo "HAPP_HTTPS=\"$HAPP_HTTPS\""                  2>/dev/null >> $APP_FILE
  echo "HAPP_URIS=\"$HAPP_URIS\""                    2>/dev/null >> $APP_FILE
  echo "HAPP_PORT=\"$HAP_NXT_PORT\""                 2>/dev/null >> $APP_FILE
  echo "HAPP_INIT=\"Y\""                             2>/dev/null >> $APP_FILE
  # Coloca no .bashrc, no diretório home da App
  local ARQ=/home/$HAPP/.bashrc
  # Precisa usar echo com Aspas simples para evitar expansão da expressão
  if ! grep "{NFAS-NodeVars}" $ARQ >/dev/null; then
    echo ""                                                                     >> $ARQ
    echo "#{NFAS-NodeVars} configurado automáticamente: Variáveis do Node.js"   >> $ARQ
    echo "export PORT=$HAPP_PORT"                                               >> $ARQ
    echo "export NODE_PORT=$HAPP_PORT"                                          >> $ARQ
    echo "export NODE_URI=$HAPP_URI"                                            >> $ARQ
    echo ""                                                                     >> $ARQ
  else
    # Altera variáveis já definidas no arquivo
    EditConfBashExport $ARQ PORT $HAPP_PORT
    EditConfBashExport $ARQ NODE_PORT $HAPP_PORT
    EditConfBashExport $ARQ NODE_URI $NODE_URI
  fi
}

#-----------------------------------------------------------------------
# Converte tipo de comunicação para Texto
function ConnType2Text(){
  if [ "$HAPP_HTTP" != "Y" ] &&  [ "$HAPP_HTTPS" == "Y" ]; then
    echo "Só HTTPS"
  elif [ "$HAPP_HTTP" == "Y" ] &&  [ "$HAPP_HTTPS" == "Y" ]; then
    echo "Ambos"
  else
    echo "Só HTTP"
  fi
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
    # Como não foi inicializado, cria default
    DEF_OPT="Só HTTPS"
    MSG+="\n\n"
  else
    DEF_OPT=$(ConnType2Text)
    MSG+="\n\n Sua opção atual é $DEF_OPT"
  fi
  MENU_IT=$(whiptail --title "$TITLE" --nocancel                       \
    --menu "$MSG" --default-item "$DEF_OPT" --fb 20 70 3               \
    "Só HTTPS" "  Só aceita conexão SEGURA (HTTP será redirecionado)"  \
    "Ambos"    "  Implementa ambos e não redireciona (inseguro)"       \
    "Só HTTP"  "  Só implementa HTTP simples (só para testes)"         \
    3>&1 1>&2 2>&3)

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
# RegEx: http://stackoverflow.com/questions/3809401/what-is-a-good-regular-expression-to-match-a-url
function GetAppUriList(){
  local URI,URIS,MSG,OK,N,T,LIN
  local TMP_ARQ="/root/tmp-uri.list"
  URIS=$HAPP_URIS
  while true; do
    # coloca cada URL em uma linha e guarda em atquivo temporário
    rm -r /root/tmp-uri.list
    for U in $URIS; do
      echo -e "$U"             2>/dev/null >> $TMP_ARQ
    done
    touch $TMP_ARQ
    # Usa o DIALOG para perguntar as URI
    # precisa de um loop porque sempre pode sair com Esc
    OK="N";
    while [ "$OK" != "Y" ]; do
      MSG="Forneca os Dominios com URI base para a Aplicação"
      URIS=$(dialog --stdout --backtitle "$TITLE" --title "$MSG"  \
        --nocancel --editbox $TMP_ARQ 18 70)
      [ $? == 0 ] && OK="Y"
    done
    OK="Y";N=0;LIN=""
    # Junta todas as URIs numa linha, verifica se são válidas
    URIS=$(echo $URIS | sed ':a;$!N;s/\n//;ta;')
    for URI in $URIS; do
      N=$((N+1))
      T=$(echo $URI | sed -n 's/\([-a-z0-9._\/]*\).*/\1/p')
      if [ "$T" != "$URI" ]; then
        OK="N"
        LIN=$N
      fi
    done
    if [ "$OK" == "Y" ]; then
      # junta todas as linhas, remove espaços repetidos
      HAPP_URIS="";T=""
      for URI in $URIS; do
        # Retira '/' no final da URI
        # T="abcd/"; echo ${T:$((${#T}-1))}; echo ${T:0:$((${#T}-1))}
        if [ "${URI:$((${#URI}-1))}" == "/" ]; then
          URI=${URI:0:$((${#URI}-1))}
        fi
        HAPP_URIS+="$T$URI"
        T=" "
      done
      echo "URIs=[$HAPP_URIS]"
      return 0
    fi
    MSG="\n A URI na linha $LIN é inválida, por favor corrija...\n\n"
    whiptail --title "$TITLE" --msgbox "$MSG" 11 60
  done
}

#-----------------------------------------------------------------------
# Edita Configurações de uma App
# Retorna: 0=alteração completada, 1=cancelada
function EditAppConfig(){
  local OPT,URI
  # Lê dados desta aplicação, se existirem
  GetSingleAppVars
  # Pergunta tipo de Conexão
  GetAppConnType
  # Pergunta
  GetAppUriList
  # Pede confirmação dos dados
  OPT=$(ConnType2Text)
  MSG=" Confirme as configurações da App: $HAPP"
  MSG+="\n\nTipo de Conexão para o seu Aplicativo: $OPT"
  MSG+="\n\nURIs para acesso ao aplicativo:"
  local HAPP_URI=""
  for URI in $HAPP_URIS; do
    # Lista URIs na tela
    MSG+="\n  $URI"
    # Guarda primeira como principal
    [ -z "$HAPP_URI" ] && HAPP_URI="$URI"
  done
  MSG+="\n\nVariáveis de ambiente criadas:"
  if [ -z "$HAPP_PORT" ];then
    MSG+="\n  PORT=$HAP_NXT_PORT"
    MSG+="\n  NODE_PORT=$HAP_NXT_PORT"
  else
    MSG+="\n  PORT=$HAPP_PORT"
    MSG+="\n  NODE_PORT=$HAPP_PORT"
  fi
  MSG+="\n  NODE_URI=$HAPP_URI"
  if ( ! whiptail --title "Configuração de Aplicativo" --yesno "$MSG" --no-button "Cancel" 20 78) then
    echo "AppConfig Cancelado"
    return 1
  fi
  # foi confirmado, grava configuração da Aplicação
  ConfigSingleApp
  return 0
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

  # Configura o rsyslog para aceitar a porta UDP:514
  # http://kvz.io/blog/2010/08/11/haproxy-logging/
  [ ! -e /etc/rsyslog.conf.orig ] && cp /etc/rsyslog.conf /etc/rsyslog.conf.orig
  sed -i '/\$ModLoad imudp/s/#//;' /etc/rsyslog.conf
  sed -i '/\$UDPServerRun 514/s/#//;' /etc/rsyslog.conf
  # Configura Logrotate (ver no monit.sh)
  local ARQ="/etc/logrotate.d/haproxy"
  if [ ! -e $ARQ ]; then
    cat <<- EOF > $ARQ
		##################################################
		##  Logrotate para o haproxy
		##################################################
		##  Depois de criado, não é mais alterado

		/var/log/haproxy.log {
		  missingok
		  notifempty
		  compress
		  delaycompress
		  size 100k
		  weekly
		  create 0600 root root
		}
		EOF
  fi

  # Volta e remove diretório temporário
  popd
  rm -rf $INSTALL_DIR
}

#-----------------------------------------------------------------------
# Configuração Básica do HAproxy
# Sem nenhuma Aplicação, apenas usado na instalação
# Config do og: http://cbonte.github.io/haproxy-dconv/configuration-1.6.html#4.2-log
function HaproxyConfigBasic(){
  local ARQ="/etc/haproxy/haproxy.cfg"
  # Se arquivo já existe, não altera
  if [ ! -e $ARQ ]; then
    echo "##################################################"               >  $ARQ
    echo "##  HAPROXY: arquivo de configuração inicial"                     >> $ARQ
    echo "##################################################"               >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "global"                                                           >> $ARQ
    echo "  maxconn 20000"                                                  >> $ARQ
    echo "  log \"\${LOCAL_SYSLOG}:514\" local0 notice"                     >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "defaults"                                                         >> $ARQ
    echo "  mode http"                                                      >> $ARQ
    echo "  option forwardfor"                                              >> $ARQ
    echo "  option http-server-close"                                       >> $ARQ
    echo "  timeout connect 5000ms"                                         >> $ARQ
    echo "  timeout client 50000ms"                                         >> $ARQ
    echo "  timeout server 50000ms"                                         >> $ARQ
    echo "  log global"                                                     >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "frontend www-http"                                                >> $ARQ
    echo "  bind :80"                                                       >> $ARQ
    echo "  default_backend http-backend"                                   >> $ARQ
    echo ""                                                                 >> $ARQ
    echo "backend http-backend"                                             >> $ARQ
  fi
   # Verifica arquivo de configuração
  haproxy -c -q -V -f /etc/haproxy/haproxy.cfg
  # instala e start serviço
  if [ "$DISTRO_NAME_VERS" == "CentOS 6" ]; then
    # usando init
    chkconfig --add haproxy
    service haproxy start
  fi
}

#-----------------------------------------------------------------------
# Configura o HAproxy
# Configurações de: https://mozilla.github.io/server-side-tls/ssl-config-generator/
function HaproxyConfig(){
  local ARQ

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
  # Restart serviço
  if [ "$DISTRO_NAME_VERS" == "CentOS 6" ]; then
    # usando init
    service haproxy restart
  fi
}

#-----------------------------------------------------------------------
# Lê dados do HAproxy se existirem
# Configura valores default
function ReadHaproxyVars(){
  # Apaga variáveis anteriores e gera compatibilidade
  HAP_CRYPT_LEVEL="2"
  HAP_NEW_CONF="N"
  HAP_NXT_PORT="3000"
  if [ -e $VAR_FILE ]; then
    # Lê arquivo já existente
    . $VAR_FILE
  fi
}
#-----------------------------------------------------------------------
# Salva variáveis de configuração
# Neste módulo as variáveis são usadas sempre apartir do arquivo de configuração Real
# Estas variáveis são guardadas apenas para recurso futuro de exportação
function SaveHaproxyVars(){
  echo "HAP_CRYPT_LEVEL=\"$HAP_CRYPT_LEVEL\""                         2>/dev/null >  $VAR_FILE
  echo "HAP_NEW_CONF=\"$HAP_NEW_CONF\""                               2>/dev/null >> $VAR_FILE
  echo "HAP_NXT_PORT=\"$HAP_NXT_PORT\""                               2>/dev/null >> $VAR_FILE
}


#=======================================================================
# main()

# Lê variáveis e configura Defauls
ReadHaproxyVars
TITLE="NFAS - Configuração do HAproxy"

if [ "$CMD" == "--first" ]; then
  # Instala HAproxy, não configura nem inicializa
  #HaproxyInstall
# ==>> Provisório, apaga para testes
rm -f /etc/haproxy/haproxy.cfg
  # Le o nível de segurança desejado, fica no $HAP_CRYPT_LEVEL
  GetHaproxyLevel
  # Cria uma configuração básica sem nada, Start serviço
  HaproxyConfigBasic

elif [ "$CMD" == "--app" ]; then
  #-----------------------------------------------------------------------
  # Lê Configurações para aquela App
  EditAppConfig
  if [ $? == 0 ]; then
    # Configuração foi alterada e aceita
    HAP_NEW_CONF="Y"
  fi

elif [ "$CMD" == "--reconfig" ]; then
  #-----------------------------------------------------------------------
  # Reconfigura HAproxy se alguma coisa mudou
  if [ "$HAP_NEW_CONF" == "Y" ]; then
    echo "---------------------"
    echo " HAproxy RECONFIGURE "
    echo "---------------------"
  fi
fi

# Salva Variáveis alteradas
SaveHaproxyVars

#=======================================================================
