#!/bin/bash
# set -x

# Script para Instalar e Configurar o HAprozy
# Uso: /script/haproxy.sh <cmd>
# <cmd>: --first       primeira instalação
# <cmd>: --app <user>  altera configuração da Aplicação
# <cmd>: --ssl         altera nível global de segurança SSL
# <cmd>: --reconfig    Reconfigura se alguma coisa mudou
# <cmd>: --certonly    Gera novo Certificado, testa antes se precisa

# Instalando o Haproxy do fonte
# @author original Marcos de Lima Carlos, adaptado por Alain Mouette
# Opções do HAproxy: "TARGET=linux2628", esta é a opção de otimização mais nova
#   para verificar se existe uma nova, use o make sem parametros:
#   cd /script/install/haproxy-1.6.3; make; cd

# Sites de DownLoad do HAproxy e Lua da versão aprovada
HAPROXY_DL="http://www.haproxy.org/download/1.6/src"
LUA_DL="http://www.lua.org/ftp"
INSTALL_DIR="/script/install"
# Configura modo de teste do Certificado Let's Encrypt
LE_TEST="N"
# Numero de dias valtando para renovação, 91=forçar sempre, 45=normal
LE_VAL=45

#-----------------------------------------------------------------------
# Strings de configuração do HAproxy
# Configurações de: https://mozilla.github.io/server-side-tls/ssl-config-generator/
#   e https://wiki.mozilla.org/Security/Server_Side_TLS#Recommended_configurations
#
# Nível 1: MODERNO
   HAP_GLOBAL_N1="  # {NFAS: set default parameters to the configuration: MODERN}"
HAP_GLOBAL_N1+="\n  tune.ssl.default-dh-param 2048"
HAP_GLOBAL_N1+="\n  ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK"
    HAP_HTTPS_N1="  bind :443 ssl no-sslv3 no-tlsv10 crt /etc/haproxy/ssl/letsencrypt.pem"
# Nível 2: INTERMEDIARIO
   HAP_GLOBAL_N2="  # {NFAS: set default parameters to the configuration: INTERMEDIATE}"
HAP_GLOBAL_N2+="\n  tune.ssl.default-dh-param 2048"
HAP_GLOBAL_N2+="\n  ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"
    HAP_HTTPS_N2="  bind :443 ssl no-sslv3 crt /etc/haproxy/ssl/letsencrypt.pem"
# Nível 3: ANTIGO
   HAP_GLOBAL_N3="  # {NFAS: set default parameters to the configuration: OLD(OBSOLETE)}"
HAP_GLOBAL_N3+="\n  tune.ssl.default-dh-param 1024"
HAP_GLOBAL_N3+="\n  ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"
    HAP_HTTPS_N3="  bind :443 ssl crt /etc/haproxy/ssl/letsencrypt.pem"

#=======================================================================
# Processa a linha de comando
CMD=$1
HAPP=$2
# Lê dados anteriores se existirem
. /script/info/distro.var
. /script/info/email.var
# Funções do sistema
. /script/functions.sh
VAR_FILE="/script/info/haproxy.var"

#-----------------------------------------------------------------------
# Pergunta nível de Segurança do HAproxy
# Nível atual em HAP_CRYPT_LEVEL
function GetHaproxyLevel(){
  local MENU_IT MSG LEVEL
  if [ "$CMD" == "--first" ]; then
    MSG="\nQual o Nível de Segurança de Criptografia para o Servidor:"
  else
    MSG="\nQual o Nível de Segurança de Criptografia (ATUAL=$HAP_CRYPT_LEVEL)"
  fi

  MENU_IT=$(whiptail --title "$TITLE" --nocancel --default-item "$HAP_CRYPT_LEVEL" \
    --menu "$MSG" --fb 20 76 3                                           \
    "1" "Moderno - Comunicação segura, só Browsers novos (nível A+)"     \
    "2" "Intermediário - Compatibilidade, aceita a maioria dos Browsers" \
    "3" "Antigo - Baixa Segurança, WinXP e IE6"                          \
    3>&1 1>&2 2>&3)
  if [ "$HAP_CRYPT_LEVEL" != "$MENU_IT" ]; then
    HAP_CRYPT_LEVEL=$MENU_IT
    # Configuração foi alterada e aceita
    HAP_NEW_CONF="Y"
  fi
  echo $MENU_IT
  return 0
}

#-----------------------------------------------------------------------
# Lê dados de uma APP se existirem
# uso: GetSingleAppVars <app>
function GetSingleAppVars(){
  local APP_FILE="/script/info/hap-$1.var"
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
  echo "HAPP_PORT=\"$HAPP_PORT\""                    2>/dev/null >> $APP_FILE
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
    "Só HTTPS" "  HTTP será redirecionado (usa HSTS para \"A+\")"  \
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
    # para PuTTY mostrar os quadros na tela com linhas
    export NCURSES_NO_UTF8_ACS=1
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
  GetSingleAppVars $HAPP
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

#-----------------------------------------------------------------------
# instala o Script do Let's Encrypt
# fica no /opt
function LetsEncryptInstall(){
  pushd /opt
  # instala no /opt/letsencrypt
  git clone https://github.com/letsencrypt/letsencrypt
  cd letsencrypt
  # Instala dependências automáticas
  ./letsencrypt-auto --os-packages-only
  popd
  # Instala chamada pelo CRON, cria chamada diária, evita repetir a alteração
  local ARQ=/etc/crontab
  if ! grep "{NFAS-letsencrypt}" $ARQ >/dev/null; then
    echo ""                                                                     >> $ARQ
    echo "#{NFAS-letsencrypt} renovação automática do certificado"              >> $ARQ
    echo "  33 3  *  *  * root /script/haproxy.sh --certonly > /root/cron-certonly.txt" >> $ARQ
    echo ""                                                                     >> $ARQ
  fi
}

#-----------------------------------------------------------------------
# Cria e autentica um Certificado no Let's encrypt
# https://blog.brixit.nl/automating-letsencrypt-and-haproxy
# Ver conteúdo do Cartificado: openssl x509 -in /etc/haproxy/ssl/letsencrypt.pem -text
function GetCertificate(){
  local APP_LIST APP URI DOM DOM1 DATE_CERT DIAS MSG
  local LE_TOOL LE_CERT_PATH LE_CERT_ATUAL
  local DOM_LIST=""
  local DOM_CERT=""
  local NEW_DOMAINS=""
  local HAS_SSL="N"
  # Cria lista das Aplicações, usuários Linux
  APP_LIST=$(GetAppList)
  echo "APP_LIST=[$APP_LIST]"
  # Varre todos os arquivos de configuração de Aplicação (HAPP_*)
  for APP in $APP_LIST; do
    if [ -e "/script/info/hap-$APP.var" ]; then
      echo "AppConfig encontrado: $APP"
      #cat "/script/info/hap-$APP.var"
      # Le dados de cada Aplicação
      GetSingleAppVars $APP
      if [ -n "$HAPP_URIS" ]; then
        # Tsta se usa SSL para esta aplicação
        if [ "$HAPP_HTTPS" == "Y" ]; then
          # varre todas as URIs para extrair os domínios
          for URI in $HAPP_URIS; do
            # Retira só o Domínio de todas as URIs
            DOM_LIST+=" $(echo "$URI" | sed -n 's@\([^\/]*\)\/\?.*@\1@p')"
          done
          HAS_SSL="Y"
        fi # Existem URIs
      fi
    fi # Exite arquvo de configuração
  done
  # Se não usa SSL em nenhuma Aplicação, retorna
  [ "$HAS_SSL" == "N" ] && return 0
  # Ordena e elimina duplicados: http://stackoverflow.com/questions/8802734/sorting-and-removing-duplicate-words-in-a-line
  DOM_LIST=$(echo "$DOM_LIST" | xargs -n1 | sort -u | xargs)
  echo "DOM_LIST=[$DOM_LIST]"
  if [ -e /etc/haproxy/ssl/letsencrypt.pem ]; then
    # Gera lista dos Domínios dentro do Certificado, mesma formatação
    DOM_CERT=$(openssl x509 -in /etc/haproxy/ssl/letsencrypt.pem -text | grep DNS | xargs -n1 | tr -d "DNS:" | tr -d "," | sort -u | xargs)
    [ -n "$DOM_CERT" ] && echo "DOM_CERT=[$DOM_CERT]"
    # Obtém a data de validade do Certificado
    DATE_CERT=$(openssl x509 -in /etc/haproxy/ssl/letsencrypt.pem -text | grep "Not After" | sed -n 's/\s*Not After : \(.*\)/\1/p')
    # Calcula número de dias faltando até vencer
    DIAS=$(( ($(date -d "$DATE_CERT" +%s) - $(date +%s)) / 86400 ))
    echo "Já existe um certificado instalado, validade: $DIAS dias"
  else
    echo "Nenhum certificado encontrado"
    DOM_CERT=""
  fi
  # Gera informações para Gerar/Ronovar Certificado
  DOM1=""
  for DOM in $DOM_LIST; do
    NEW_DOMAINS+=" -d $DOM"
    [ -z "$DOM1" ] && DOM1="$DOM" # Guarda 1º da lista
  done
  # Path onde é guardado o Certificado
  LE_CERT_PATH="/etc/letsencrypt/live/$DOM1"
  # Path to the letsencrypt-auto tool
  LE_TOOL=/opt/letsencrypt/letsencrypt-auto
  [ "$LE_TEST" == "Y" ] && LE_TOOL+=" --test-cert"
  # Agora pode testar se vai mesmo fazer...
  if [ "$DOM_LIST" != "$DOM_CERT" ]; then
    echo -e "\n         ┌──────────────────────────────────────┐"
    echo -e   "         │      Gerando Certificado SSL ...     │"
    echo -e   "         └──────────────────────────────────────┘\n"
#set -x
    echo "NEW_DOMAINS=[$NEW_DOMAINS]"
    # Elimina dados de certificados anteriores, senão fica acumulando e renovando os velhos
    rm -rf /etc/letsencrypt/archive/*
    rm -rf /etc/letsencrypt/live/*
    rm -rf /etc/letsencrypt/renewal/*
    # Create or renew certificate for the domain(s) supplied for this tool
    # Usa "tls-sni-01" para porta 443
    # Usar "--test-cert" para teste (staging)
    $LE_TOOL --agree-tos --renew-by-default --email "$EMAIL_ADMIN" \
             --standalone --standalone-supported-challenges        \
             http-01 --http-01-port 9999 certonly $NEW_DOMAINS 2>&1 | tee /root/certoutput.txt
    MSG="Seu novo Certificado foi gerado, saida:\n--------------------\n"
    MSG+="$(cat /root/certoutput.txt)\n--------------------"
    if [ $? -eq 0 ]; then
      echo -e "$MSG" | tr -cd '\11\12\15\40-\176' | mail -s "Certificado gerado para [$(hostname)] - OK" $EMAIL_ADMIN
      LE_CERT_ATUAL="$(cat /root/certoutput.txt | sed -n 's/.*\/etc\/letsencrypt\/live\/\(.*\)\/fullchain.pem.*/\1/p')"
      if [ "$DOM1" != "$LE_CERT_ATUAL" ]; then
        echo "Primeiro comínio : $DOM1"
        echo "Reportado no Cert: $LE_CERT_ATUAL"
        echo "ERRO: Certificado não foi guardado no diretório esperado"
        read -p "Pressione <Enter> para continuar" A
      fi
      # Cat the certificate chain and the private key together for haproxy
      # Fica guardado com o nome do primeiro certificado (ordem alfabetica...)
      rm -rf /etc/haproxy/ssl/*
      cat $LE_CERT_PATH/{fullchain.pem,privkey.pem} > /etc/haproxy/ssl/letsencrypt.pem # | sed -n 's/\(.*\)-.*/\1/p'
      # Guarda Path para uso futuro, só o último é válido
      echo "LE_CERT_PATH=$LE_CERT_PATH" > /script/info/letsencrypt.var
      # Reload the haproxy daemon to activate the cert
      service haproxy reload
    else
      echo -e "$MSG" | tr -cd '\11\12\15\40-\176' | mail -s "ERRO gerando certificado para [$(hostname)]" $EMAIL_ADMIN
      echo "Erro gerando Certificado"
    fi
  elif [ $DIAS -lt $LE_VAL ]; then
    echo -e "\n         ┌────────────────────────────────────────┐"
    echo -e   "         │      Renovando Certificado SSL ...     │"
    echo -e   "         └────────────────────────────────────────┘\n"
#set -x
    # Renova com mesmo sistema automático
    # Usar "--test-cert" para teste (staging)
    # Usar "--renew-by-default" para forçar renovação
    $LE_TOOL --renew-by-default --email "$EMAIL_ADMIN" renew 2>&1 | tee /root/certoutput.txt
    MSG="Seu Certificado foi RENOVADO, saida:\n--------------------\n"
    MSG+="$(cat /root/certoutput.txt)\n--------------------"
    if [ $? -eq 0 ]; then
      echo -e "$MSG" | tr -cd '\11\12\15\40-\176' | mail -s "Certificado RENOVADO para [$(hostname)] - OK" $EMAIL_ADMIN
      # Path do Certificado, informado pelo Let's encrypt
      LE_CERT_ATUAL=$(cat /root/certoutput.txt | sed -n -e '/have been renewed/,$p' | sed -n 's/.*\/etc\/letsencrypt\/live\/\(.*\)\/fullchain.pem.*/\1/p')
      # Cat the certificate chain and the private key together for haproxy
      # Fica guardado com o nome do primeiro certificado (ordem alfabetica...)
      rm -rf /etc/haproxy/ssl/*
      cat $LE_CERT_PATH/{fullchain.pem,privkey.pem} > /etc/haproxy/ssl/letsencrypt.pem
      # Guarda Path para uso futuro, só o último é válido
      echo "LE_CERT_PATH=$LE_CERT_PATH" > /script/info/letsencrypt.var
      # Reload the haproxy daemon to activate the cert
      service haproxy reload
    else
      echo -e "$MSG" | tr -cd '\11\12\15\40-\176' | mail -s "ERRO renovando certificado para [$(hostname)]" $EMAIL_ADMIN
      echo "Erro renovando Certificado"
    fi
  fi
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

  local LUA_CUR_VER=$(lua -v | sed -n 's/.* \([0-9]*\.[0-9]*\).*/\1/p')
  if [ "$LUA_CUR_VER" != "5.3" ]; then
    # Carrega última versão do Lua 5.3
    HAPROXY_LUA_VER=$(GetVerLua)
    rm -f $HAPROXY_LUA_VER.tar.gz
    wget $LUA_DL/$HAPROXY_LUA_VER.tar.gz
    tar xf $HAPROXY_LUA_VER.tar.gz
    cd $HAPROXY_LUA_VER
    make linux
    make install
    cd $INSTALL_DIR
  fi

  local HAP_CUR_VER=$(haproxy -v | grep "HA-Proxy version" | sed -n 's/.* \([0-9]*\.[0-9]*\).*/\1/p')
  if [ "$HAP_CUR_VER" != "1.6" ]; then
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

    # copia o init.d e dá permissão de execução (usa mesma dos outros arquivos).
    # TODO: usar uptart/systemd CentOS/Ubuntu, testar $DISTRO_NAME
    cp examples/haproxy.init /etc/init.d/haproxy
    chmod 755 /etc/init.d/haproxy
    # copia os arquivos de erro
    mkdir -p /etc/haproxy/errors
    cp examples/errorfiles/* /etc/haproxy/errors
    chmod 600 /etc/haproxy/errors
    # diretório para certificados
    mkdir -p /etc/haproxy/ssl

    # adiciona grupo, usuário e diretório do haproxy, precisa para CHROOT
    id -g haproxy &>/dev/null || groupadd haproxy
    id -u haproxy &>/dev/null || useradd -g haproxy -s /usr/sbin/nologin -r haproxy
    # cria os diretórios em etc e stats.
    mkdir -p /var/lib/haproxy
    touch /var/lib/haproxy/stats
    # Configura o rsyslog para aceitar a porta UDP:514, precisa para CHROOT
    [ ! -e /etc/rsyslog.conf.orig ] && cp /etc/rsyslog.conf /etc/rsyslog.conf.orig
    sed -i '/\$ModLoad imudp/s/#//;' /etc/rsyslog.conf
    sed -i '/\$UDPServerRun 514/s/#//;' /etc/rsyslog.conf
    service rsyslog reload

    # configura o rsyslog para o haproxy
    # http://serverfault.com/questions/214312/how-to-keep-haproxy-log-messages-out-of-var-log-syslog
    local ARQ="/etc/rsyslog.d/49-haproxy.conf"
    if [ ! -e $ARQ ]; then
      cat <<- EOF > $ARQ
      # file: /etc/rsyslog.d/49-haproxy.conf:
      local0.* -/var/log/haproxy.log
      & stop
      # & ~ means not to put what matched in the above line anywhere else for the rest of the rules
      # ~ is obsolete, now use "stop"
      EOF
    fi
    # Configura Logrotate (ver no monit.sh)
    ARQ="/etc/logrotate.d/haproxy"
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
  fi
  # Volta e remove diretório temporário
  popd
  rm -rf $INSTALL_DIR
}

#-----------------------------------------------------------------------
# Reconfigura o HAproxy
# Configurações de: https://mozilla.github.io/server-side-tls/ssl-config-generator/
function HaproxyReconfig(){
  local ARK APP U USR URI URIS DOM DIR PORT HTTP HTTPS NACL APP_LIST TMP_FRONT
  local SORT_LIST=""
  local HTTP_FRONT=""
  local HTTPS_FRONT=""
  local HTTP_BAK=""
  local HAS_HTTP="N"
  local HAS_SSL="N"
  local ARQ="/etc/haproxy/haproxy.cfg"
  # Cria lista das Aplicações, usuários Linux
  APP_LIST=$(GetAppList)
  echo "APP_LIST=[$APP_LIST]"
  # Varre todos os arquivos de configuração de Aplicação
  for APP in $APP_LIST; do
    if [ -e "/script/info/hap-$APP.var" ]; then
      # echo "AppConfig encontrado: $APP"
      # cat "/script/info/hap-$APP.var"
      # Le dados de cada Aplicação
      GetSingleAppVars $APP
      if [ -n "$HAPP_URIS" ]; then
        # Cria uma Lista com todas as informações da Aplicação
        for URI in $HAPP_URIS; do
          DOM="$(echo "$URI" | sed -n 's@\([^\/]*\)\/\?.*@\1@p')"
          DIR="$(echo "$URI" | sed -n 's@[^\/]*\(.*\)@\1@p')"
          # Cria lista de ACLs para ordenar
          SORT_LIST+="$(( 1000- ${#DOM} ))	\"$DOM\"	$(( 1000- ${#DIR} ))	\"$DIR\"	$APP	$HAPP_PORT	$HAPP_HTTP	$HAPP_HTTPS\n"
        done
        # Flags para todas as Aplicações
        [ "$HAPP_HTTP"  == "Y" ] && HAS_HTTP="Y"
        [ "$HAPP_HTTPS" == "Y" ] && HAS_SSL="Y"
        # Cria todos os Backends
        HTTP_BAK+="\n#{NFAS HTTP-BAK: $APP}\n"
        HTTP_BAK+="backend http-$APP\n"
        HTTP_BAK+="  option forwardfor # Original IP address\n"
        HTTP_BAK+="  http-response set-header X-Frame-Options SAMEORIGIN  # no clickjacking\n"
        if [ "$HAPP_HTTP" == "N" ] && [ "$HAPP_HTTPS" == "Y" ]; then
          # Acrescenta HSTS, só se deve redirecionar. Tem que ser > 6 mêses, 16000000
          HTTP_BAK+="  http-response set-header Strict-Transport-Security \"max-age=16000000; includeSubDomains; preload;\"\n"
        fi
        HTTP_BAK+="  server srv-$APP 127.0.0.1:$HAPP_PORT check\n"
      fi # Existem URIs
    fi # Exite arquvo de configuração
  done #APP_LIST
  SORT_LIST=$(echo -ne "$SORT_LIST" | sort -k1,1n -k2,2 -k3,3n -k4,4)
  echo -ne "$SORT_LIST" > sortlist.txt
  NACL=1
  while read -r ACL; do
    APP=$(echo -e "$ACL" | cut -f5)
    DOM=$(echo -e "$ACL" | cut -f2 | sed -e 's/^"//' -e 's/"$//')
    DIR=$(echo -e "$ACL" | cut -f4 | sed -e 's/^"//' -e 's/"$//')
    PORT=$(echo -e "$ACL" | cut -f6)
    HTTP=$(echo -e "$ACL" | cut -f7)
    HTTPS=$(echo -e "$ACL" | cut -f8)
    echo "===== APP=$APP DOM=$DOM DIR=$DIR HTTP=$HTTP HTTPS=$HTTPS ====="
    TMP_FRONT="  # APP=$APP, URI=$DOM$DIR\n"
    if [ -z "$DIR" ]; then
      # Cotém só domínio
      TMP_FRONT+="  acl host_"$APP"_"$NACL" req.hdr(host) -i $DOM\n"
      if [ "$HTTP" == "N" ] && [ "$HTTPS" == "Y" ]; then
        # Precisa redirecionar
        HTTP_FRONT+=$TMP_FRONT
        HTTPS_FRONT+=$TMP_FRONT
        # HTTP faz redirect
        HTTP_FRONT+="  use_backend http-redirect if host_"$APP"_"$NACL"\n"
        # HTTPS vai para a aplicação
        HTTPS_FRONT+="  use_backend http-$APP if host_"$APP"_"$NACL"\n"
      else
        TMP_FRONT+="  use_backend http-$APP if host_"$APP"_"$NACL"\n"
        # Adiciona frontends, pode ser só HTTP ou nos dois
        [ "$HTTP" == "Y" ]  && HTTP_FRONT+=$TMP_FRONT
        [ "$HTTPS" == "Y" ] && HTTPS_FRONT+=$TMP_FRONT
      fi
    else
      if [ -n "$DOM" ]; then
        # Com domínio e com rota
        TMP_FRONT+="  acl host_"$APP"_"$NACL"h req.hdr(host) -i $DOM\n"
        TMP_FRONT+="  acl host_"$APP"_"$NACL"d path_dir -i $DIR\n"
        if [ "$HTTP" == "N" ] && [ "$HTTPS" == "Y" ]; then
          # Precisa redirecionar
          HTTP_FRONT+=$TMP_FRONT
          HTTPS_FRONT+=$TMP_FRONT
          # HTTP faz redirect
          HTTP_FRONT+="  use_backend http-redirect if host_"$APP"_"$NACL"h host_"$APP"_"$NACL"d\n"
          # HTTPS vai para a aplicação
          HTTPS_FRONT+="  use_backend http-$APP if host_"$APP"_"$NACL"h host_"$APP"_"$NACL"d\n"
        else
          TMP_FRONT+="  use_backend http-$APP if host_"$APP"_"$NACL"h host_"$APP"_"$NACL"d\n"
        # Adiciona frontends, pode ser só HTTP ou nos dois
        [ "$HTTP" == "Y" ]  && HTTP_FRONT+=$TMP_FRONT
        [ "$HTTPS" == "Y" ] && HTTPS_FRONT+=$TMP_FRONT
        fi
      elif [ "$HTTP" == "Y" ]; then
        # Sem domínio, acesso direto. Começa com '/'
        # Precisa usar uma RegEx para identificar acesso só por IP ("-m ip" não funcionou)
        # Só pode ser com HTTP, TODO: testar IPv6
        HTTP_FRONT+=$TMP_FRONT
        HTTP_FRONT+="  acl host_"$APP"_"$NACL"h req.hdr(host) -m reg ^[0-9\.]*$\n"
        HTTP_FRONT+="  acl host_"$APP"_"$NACL"h req.hdr(host) -i -m reg ^[0-9a-f:]*$\n"
        HTTP_FRONT+="  acl host_"$APP"_"$NACL"d path_dir -i $DIR\n"
        HTTP_FRONT+="  use_backend http-$APP if host_"$APP"_"$NACL"h host_"$APP"_"$NACL"d\n"
      fi
    fi
    # Indexador das ACLs
    NACL=$(( $NACL + 1 ))
  done <<< "$SORT_LIST"
  # echo -e "HTTP_FRONT:\n$HTTP_FRONT"
  # echo -e "HTTPS_FRONT:\n$HTTPS_FRONT"
  # Cria o arquivo de configuração
  ARQ="/etc/haproxy/haproxy.cfg"
  echo "##################################################"               >  $ARQ
  echo "##  HAPROXY: arquivo de configuração principal"                   >> $ARQ
  echo "##################################################"               >> $ARQ
  echo "##  Não altere, será recriado integralmente"                      >> $ARQ
  echo ""                                                                 >> $ARQ
  echo "global"                                                           >> $ARQ
  echo "  maxconn 20000"                                                  >> $ARQ
  #echo "  log /dev/log local0 notice # notice/info/debug"                >> $ARQ
  echo "  log "\${LOCAL_SYSLOG}:514" local0 notice # notice/info/debug"   >> $ARQ
  echo "  user   haproxy"                                                 >> $ARQ
  echo "  group  haproxy"                                                 >> $ARQ
  echo "  chroot /var/lib/haproxy"                                        >> $ARQ
  if [ "$HAS_SSL" == "Y" ]; then
    # Configurações para cada nível de criptografia
    if [ "$HAP_CRYPT_LEVEL" == "1" ]; then
      echo -e "$HAP_GLOBAL_N1"                                            >> $ARQ
    elif [ "$HAP_CRYPT_LEVEL" == "3" ]; then
      echo -e "$HAP_GLOBAL_N3"                                            >> $ARQ
    else
      # default é nível Intermediário
      echo -e "$HAP_GLOBAL_N2"                                            >> $ARQ
    fi
  fi
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
  if [ "$HAS_SSL" == "Y" ]; then
    echo "  #{NFAS HTTPS-FRONT: Automação do Lets Encrypt}"               >> $ARQ
    echo "  acl letsencrypt-request path_beg -i /.well-known/acme-challenge/">> $ARQ
    echo "  use_backend letsencrypt if letsencrypt-request"               >> $ARQ
  fi
  # Configurações FrontEnd de cada aplicação
  echo -e "$HTTP_FRONT"                                                   >> $ARQ
  # Não tem site default
  # echo "  default_backend http-backend"                                 >> $ARQ
  if [ "$HAS_SSL" == "Y" ]; then
    # Fornt-End do HTTPS e do Lets Encrypt
    echo "frontend www-https"                                             >> $ARQ
    if [ -e /etc/haproxy/ssl/letsencrypt.pem ]; then
      # Já existe certificado atual ou anterior
      if [ "$HAP_CRYPT_LEVEL" == "1" ]; then
        echo -e "$HAP_HTTPS_N1"                                           >> $ARQ
      elif [ "$HAP_CRYPT_LEVEL" == "3" ]; then
        echo -e "$HAP_HTTPS_N3"                                           >> $ARQ
      else
        # default é nível Intermediário
        echo -e "$HAP_HTTPS_N2"                                           >> $ARQ
      fi
      # Alerações do Header devem vir primeiro
      echo -e "  http-request set-header X-Forwarded-Proto https"         >> $ARQ
      # Se está na porta 443 mas não está encriptado, redireciona. "code 301" é: moved permanently
      echo -e "  redirect scheme https if !{ ssl_fc }"                    >> $ARQ
      # Configurações FrontEnd de cada aplicação
      echo -e "$HTTPS_FRONT"                                              >> $ARQ
    else
      # ainda não tem nenhum certificado
      echo "  bind :443"                                                  >> $ARQ
    fi
  else
    echo "#{NFAS: Nenhuma Aplicação com SSL}"                             >> $ARQ
  fi
  # Cria BackEnds
  echo -e "$HTTP_BAK"                                                     >> $ARQ
  if [ "$HAS_SSL" == "Y" ]; then
    # Backend para redirecionar HTTP=>HTTPS na sequência correta
    echo "#{NFAS HTTPS-BAK: Redireciona HTTP}"                            >> $ARQ
    echo "backend http-redirect"                                          >> $ARQ
    echo "  redirect scheme https"                                        >> $ARQ
    # Por último Backend do Lets encrypt
    echo ""                                                               >> $ARQ
    echo "#{NFAS HTTPS-BAK: Automação do Lets Encrypt}"                   >> $ARQ
    echo "backend letsencrypt"                                            >> $ARQ
    echo "  server letsencrypt 127.0.0.1:9999"                            >> $ARQ
  fi
  # Não tem site default
  # echo "backend http-backend"                                           >> $ARQ
  # Configura acesso restrito
  chmod 600 $ARQ
  # Verifica arquivo de configuração e guarda para debug
  haproxy -c -q -V -f /etc/haproxy/haproxy.cfg >/root/haproxy.check
  # instala e start serviço
  if [ "$CMD" == "--first" ]; then
    # Precisa instalar e start serviço
    if [ "$DISTRO_NAME_VERS" == "CentOS 6" ]; then
      # usando init
      chkconfig --add haproxy
      chkconfig --level 345 haproxy on
      service haproxy start
    fi
  else
    # restart do serviço
    service haproxy restart
  fi
  HAP_NEW_CONF="N"
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
  HaproxyInstall
  # Instala scripts do Let's Encrypt e dependências
  LetsEncryptInstall
  # Le o nível de segurança desejado, fica no $HAP_CRYPT_LEVEL
  GetHaproxyLevel
  # Cria uma configuração básica sem nada, Start serviço
  HaproxyReconfig

elif [ "$CMD" == "--app" ]; then
  #-----------------------------------------------------------------------
  # Lê Configurações para aquela App
  EditAppConfig
  if [ $? == 0 ]; then
    # Configuração foi alterada e aceita
    HAP_NEW_CONF="Y"
  fi

elif [ "$CMD" == "--ssl" ]; then
  #-----------------------------------------------------------------------
  # Le o nível de segurança desejado, fica no $HAP_CRYPT_LEVEL
  GetHaproxyLevel

elif [ "$CMD" == "--reconfig" ]; then
  #-----------------------------------------------------------------------
  # Reconfigura HAproxy se alguma coisa mudou
  echo "---------------------"
  echo " HAproxy RECONFIGURE "
  echo "---------------------"
  # Faz uma configuração preliminar, precisa dar acesso para criar certificado
  HaproxyReconfig
  # Consegue Certificado, se precisar
  GetCertificate
  # refaz a configuração do HTTP, portas 80 e 443
  HaproxyReconfig

elif [ "$CMD" == "--certonly" ]; then
  #-----------------------------------------------------------------------
  # Deve ser chamado do CRON, vem sem environment
  SHELL=/bin/bash
  PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
  # Cria timestamp no log
  date
  # Consegue Certificado, se precisar
  GetCertificate

fi
  # Salva Variáveis alteradas
SaveHaproxyVars

#=======================================================================
