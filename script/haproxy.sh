#!/bin/bash
# set -x

# Script for installing and configuring  HAprozy
# Usage: /script/haproxy.sh <cmd>
# <cmd>: --first          First install
# <cmd>: --hostname       Reconfigure for new Hostname
# <cmd>: --email          Reconfigure for new Email
# <cmd>: --ssl            Change global HAproxy SSL secutity level
# <cmd>: --newapp         create default config for new Application
# <cmd>: --appconn <app>  Get Connection type for one Application
# <cmd>: --appuris <app>  Edit list of URIs
# <cmd>: --reconfig       Reconfigure everything, when anything changed
# <cmd>: --certonly       Generate a new Certificate, check if it is needed

# <cmd>: --app <user>     altera configuração da Aplicação           <= old?

# Installing Haproxy from source
# @original by Marcos de Lima Carlos, adapted by Alain Mouette
# HAproxy options: "TARGET=linux2628", this is a new optimization option
#   to check it there is a newer one, use make without parameters:
#   cd /script/install/haproxy-1.6.3; make; cd

# Process command line
CMD=$1
HAPP=$2
# Auxiliary Functions
. /script/functions.sh
# Read previous configurations if they exist
. /script/info/hostname.var
. /script/info/email.var
. /script/info/distro.var
. /script/info/email.var
. /script/info/virtualbox.var
# HAproxy variables
VAR_FILE="/script/info/haproxy.var"
# DownLoad sites for HAproxy and Lua, accepted version
HAPROXY_DL="http://www.haproxy.org/download/1.6/src"
LUA_DL="http://www.lua.org/ftp"
INSTALL_DIR="/script/install"
# Setup test mode for Let's Encrypt Certificate
LE_TEST="N"
# Number of days before certificate renew, 91=force always, 45=default
LE_VAL=45

#-----------------------------------------------------------------------
# Config Strings for HAproxy
# Config from: https://mozilla.github.io/server-side-tls/ssl-config-generator/
#   and https://wiki.mozilla.org/Security/Server_Side_TLS#Recommended_configurations
#
# Level 1: MODERN
   HAP_GLOBAL_N1="  # {NFAS: set default parameters to the configuration: MODERN}"
HAP_GLOBAL_N1+="\n  tune.ssl.default-dh-param 2048"
HAP_GLOBAL_N1+="\n  ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK"
    HAP_HTTPS_N1="  bind :443 ssl no-sslv3 no-tlsv10 crt /etc/haproxy/ssl/letsencrypt.pem"
# Level 2: INTERMEDIATE/COMPATIBILITY
   HAP_GLOBAL_N2="  # {NFAS: set default parameters to the configuration: INTERMEDIATE}"
HAP_GLOBAL_N2+="\n  tune.ssl.default-dh-param 2048"
HAP_GLOBAL_N2+="\n  ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"
    HAP_HTTPS_N2="  bind :443 ssl no-sslv3 crt /etc/haproxy/ssl/letsencrypt.pem"
# Level 3: OLD
   HAP_GLOBAL_N3="  # {NFAS: set default parameters to the configuration: OLD(OBSOLETE)}"
HAP_GLOBAL_N3+="\n  tune.ssl.default-dh-param 1024"
HAP_GLOBAL_N3+="\n  ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"
    HAP_HTTPS_N3="  bind :443 ssl crt /etc/haproxy/ssl/letsencrypt.pem"

#=======================================================================

#-----------------------------------------------------------------------
# Ask global HAproxy security level
# current level in HAP_CRYPT_LEVEL
function GetHaproxyLevel(){
  local MENU_IT MSG LEVEL
  if [ "$CMD" == "--first" ]; then
    MSG="\nSelect GLOBAL cryptography security level for this server:"
  else
    MSG="\nSelect GLOBAL cryptography security level (Current=$HAP_CRYPT_LEVEL)"
  fi

  MENU_IT=$(whiptail --title "$TITLE" --nocancel --default-item "$HAP_CRYPT_LEVEL" \
    --menu "$MSG" --fb 20 75 3                                               \
    "1" "Modern       - Enforce secure comunication and modern Browsers (A+)"\
    "2" "Intermediate - Compatibility, accepts most Browsers"                \
    "3" "Antique      - Low security, WinXP e IE6"                           \
    3>&1 1>&2 2>&3)
  if [ "$HAP_CRYPT_LEVEL" != "$MENU_IT" ]; then
    HAP_CRYPT_LEVEL=$MENU_IT
    # Configuration was changed and accepted
    HAP_NEW_CONF="Y"
  fi
  # echo $MENU_IT
  return 0
}

#-----------------------------------------------------------------------
# Read APP configuration if it exists, set default for compatibility
# usage: GetSingleAppVars <app>
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
# Create Default configuration for a new Application
# usage: SaveSingleAppVars <app>
function SaveSingleAppVars(){
  local HAPP=$1
  local APP_FILE="/script/info/hap-$HAPP.var"
  # if there was no PORT set, use next and recalculate
  if [ -z "$HAPP_PORT" ]; then
    HAPP_PORT=$HAP_NXT_PORT
    # NOTE: HAP_* are are read and saved for every run of haproxy.sh
    HAP_NXT_PORT=$(( $HAP_NXT_PORT + 100 ))
  fi
  echo "HAPP_HTTP=\"$HAPP_HTTP\""                    2>/dev/null >  $APP_FILE
  echo "HAPP_HTTPS=\"$HAPP_HTTPS\""                  2>/dev/null >> $APP_FILE
  echo "HAPP_URIS=\"$HAPP_URIS\""                    2>/dev/null >> $APP_FILE
  echo "HAPP_PORT=\"$HAPP_PORT\""                    2>/dev/null >> $APP_FILE
  echo "HAPP_INIT=\"Y\""                             2>/dev/null >> $APP_FILE
}

#-----------------------------------------------------------------------
# Save config variables and configure one Application
# Use variable $HAPP for identification
function ConfigSingleApp(){
  local APP_FILE="/script/info/hap-$HAPP.var"
  # save config variables and set defaults
  SaveSingleAppVars $HAPP
  # Get first URI to set as default
  local HAPP_URI=""
  for URI in $HAPP_URIS; do
    # Save first as "main URI"
    [ -z "$HAPP_URI" ] && HAPP_URI="$URI"
  done
  # Config in .bashrc, in the App's home directory
  local ARQ=/home/$HAPP/.bashrc
  # This needs to be set with echo to cope with variable expansion
  if ! grep "{NFAS-NodeVars}" $ARQ >/dev/null; then
    echo ""                                                                     >> $ARQ
    echo "#{NFAS-NodeVars} automatic configuration: Variables for Node.js"      >> $ARQ
    echo "export PORT=$HAPP_PORT"                                               >> $ARQ
    echo "export ROOT_URL=$HAPP_URI"                                            >> $ARQ
    echo ""                                                                     >> $ARQ
  else
    # Altera variáveis já definidas no arquivo
    EditConfBashExport $ARQ PORT $HAPP_PORT
    EditConfBashExport $ARQ ROOT_URL $HAPP_URI
    # EditConfBashExport $ARQ NODE_PORT $HAPP_PORT
  fi
}

#-----------------------------------------------------------------------
# Converts connection type to text
function ConnType2Text(){
  if [ "$HAPP_HTTP" != "Y" ] &&  [ "$HAPP_HTTPS" == "Y" ]; then
    echo "HTTPS only"
  elif [ "$HAPP_HTTP" == "Y" ] &&  [ "$HAPP_HTTPS" == "Y" ]; then
    echo "Both"
  else
    echo "HTTP only"
  fi
}

#-----------------------------------------------------------------------
# Ask the Connection Security Level for an application: HTTP and/or HTTPS
# Uses $HAPP for application name
# Returns: ErrLevel 0=changed, 1=aborted, Text: "HPPT only"/"Both"/"HTTPS only"
function GetAppConnType(){
  local DEF_OPT MSG MENU_IT
  # Read configs for one App, it they exist
  GetSingleAppVars $HAPP
   MSG="\nSelect the Connection type for this Application: $HAPP"
  MSG+="\nCertificates will be provided automaticaly using Let's Encrypt."
  if [ "$HAPP_INIT" != "Y" ]; then
    # Has not been initialized: create default
    DEF_OPT="HTTPS only"
    MSG+="\n\n"
  else
    DEF_OPT=$(ConnType2Text)
    MSG+="\n\n Your current option is $DEF_OPT"
  fi
  MENU_IT=$(whiptail --title "$TITLE" --nocancel                       \
    --menu "$MSG" --default-item "$DEF_OPT" --fb 20 70 3               \
    "HTTPS only" "  HTTP will be redirected (uses HSTS for \"A+\")"    \
    "Both"       "  Implement both and do not redirect (unsafe)"       \
    "HTTP only"  "  Implement only simple HTTP (for test only)"        \
    3>&1 1>&2 2>&3)

  # Interpreta Opções
  if [ "$MENU_IT" == "HTTPS only" ];then
    HAPP_HTTP="N"
    HAPP_HTTPS="Y"
  elif [ "$MENU_IT" == "Both" ];then
    HAPP_HTTP="Y"
    HAPP_HTTPS="Y"
  else
    HAPP_HTTP="Y"
    HAPP_HTTPS="N"
  fi
  if [ "$DEF_OPT" != "$MENU_IT" ]; then
    # Changed, save and reconfigure
    ConfigSingleApp
  fi
  return 0
}

#-----------------------------------------------------------------------
# Ask Domains and URIs for one Application
# Accepts list, show previous one for editing
# Retorns: 0=editon complete, 1=canceled
# RegEx: http://stackoverflow.com/questions/3809401/what-is-a-good-regular-expression-to-match-a-url
function GetAppUriList(){
  local URI URIS OLD_URIS MSG OK N T LIN
  local TMP_ARQ="/root/tmp-uri.list"
  # Read configs for this App, if exist
  GetSingleAppVars $HAPP
  # Previous list of URIs
  OLD_URIS=$HAPP_URIS
  URIS=$HAPP_URIS
  while true; do
    # Put each URL in one line and save in a temporary file
    rm -r $TMP_ARQ
    for U in $URIS; do
      echo -e "$U"             2>/dev/null >> $TMP_ARQ
    done
    touch $TMP_ARQ
    # Use DIALOG to ask/edit URIs
    # for PuTTY to show screen boxes as lines (Windows)
    export NCURSES_NO_UTF8_ACS=1
    # This must be a loop, Dialog can allways exit with an Esc
    OK="N";
    while [ "$OK" != "Y" ]; do
      MSG="List all base domains with URIs for the Application"
      URIS=$(dialog --stdout --backtitle "$TITLE" --title "$MSG"  \
        --nocancel --editbox $TMP_ARQ 18 70)
      [ $? == 0 ] && OK="Y"
    done
    clear # dialog screen is not erased
    OK="Y";N=0;LIN=""
    # Join all URIs in one line, check if they are valid
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
      # Join all lines, remove duplicated spaces
      HAPP_URIS="";T=""
      for URI in $URIS; do
        # Remove '/' at the end of URIs
        # T="abcd/"; echo ${T:$((${#T}-1))}; echo ${T:0:$((${#T}-1))}
        if [ "${URI:$((${#URI}-1))}" == "/" ]; then
          URI=${URI:0:$((${#URI}-1))}
        fi
        HAPP_URIS+="$T$URI"
        T=" "
      done
      echo "URIs=[$HAPP_URIS] old=[$OLD_URIS]"
      if [ "$OLD_URIS" != "$HAPP_URIS" ]; then
        # Configuration has changed, set Application
        ConfigSingleApp
      fi
      return 0
    fi
    MSG="\n The URI in line $LIN is invalid, please fix it...\n\n"
    whiptail --title "$TITLE" --msgbox "$MSG" 11 60
  done
}

#----------------------------------------------------------------------- <= Obsolete
# Edit one Application configurations
# Retorns: 0=changes completed, 1=aborted
function EditAppConfig(){
  local OPT,URI
  # Read configs for this App, if exist
  GetSingleAppVars $HAPP
  # Ask list of URIs and Domains
  GetAppUriList
  # Ask for confirmation
  OPT=$(ConnType2Text)
  MSG=" Confirme as configurações da App: $HAPP"
  MSG+="\n\nTipo de Conexão para o seu Aplicativo: $OPT"
  MSG+="\n\nURIs para acesso ao aplicativo:"
  local HAPP_URI=""
  for URI in $HAPP_URIS; do
    # List URIs on screen
    MSG+="\n  $URI"
    # Save first as "main URI"
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
  MSG+="\n  ROOT_URL=$HAPP_URI"
  if ( ! whiptail --title "Configuração de Aplicativo" --yesno "$MSG" --no-button "Cancel" 20 78) then
    echo "AppConfig Cancelado"
    return 1
  fi
  # confirmed, save Application configs
  ConfigSingleApp
  return 0
}

#-----------------------------------------------------------------------
# Install Let's Encrypt
# goes in /opt
function LetsEncryptInstall(){
  pushd /opt
  # Install in /opt/letsencrypt
  git clone https://github.com/letsencrypt/letsencrypt
  cd letsencrypt
  # Install automatic dependencies
  ./letsencrypt-auto --os-packages-only
  popd
  # Install CRON call, create a daily call, avoid repeating the operation
  local ARQ=/etc/crontab
  if ! grep "{NFAS-letsencrypt}" $ARQ >/dev/null; then
    echo ""                                                                     >> $ARQ
    echo "#{NFAS-letsencrypt} automatic certificate renewal"                    >> $ARQ
    echo "  33 3  *  *  * root /script/haproxy.sh --certonly > /root/cron-certonly.txt" >> $ARQ
    echo ""                                                                     >> $ARQ
  fi
}

#-----------------------------------------------------------------------
# Create and autenticate a Certificate with Let's encrypt
# https://blog.brixit.nl/automating-letsencrypt-and-haproxy
# See the Certificate content: openssl x509 -in /etc/haproxy/ssl/letsencrypt.pem -text
function GetCertificate(){
  local APP_LIST APP URI DOM DOM1 DATE_CERT DAYS MSG
  local LE_TOOL LE_CERT_PATH LE_CURRENT_CERT
  local DOM_LIST=""
  local DOM_CERT=""
  local NEW_DOMAINS=""
  local HAS_SSL="N"
  # If in Virtualbox, don't make certificate
  [ "$IS_VIRTUALBOX" == "Y" ] && return 1
  # Create a lista of Applications, Linux users
  APP_LIST=$(GetAppList)
  echo "APP_LIST=[$APP_LIST]"
  # Scan all Application configuration files (HAPP_*)
  for APP in $APP_LIST; do
    if [ -e "/script/info/hap-$APP.var" ]; then
      echo "AppConfig encontrado: $APP"
      # cat "/script/info/hap-$APP.var"
      # Read Application data
      GetSingleAppVars $APP
      if [ -n "$HAPP_URIS" ]; then
        # Test if SSL is used for this Application
        if [ "$HAPP_HTTPS" == "Y" ]; then
          # Scan all URIs to extract the domains
          for URI in $HAPP_URIS; do
            # Extract only the domain from the URIs
            DOM_LIST+=" $(echo "$URI" | sed -n 's@\([^\/]*\)\/\?.*@\1@p')"
          done
          HAS_SSL="Y"
        fi # Exist URIs
      fi
    fi # Exit configuration file
  done
  # If not using SSL in any Application, retorns
  [ "$HAS_SSL" == "N" ] && return 0
  # Sort and eliminade duplicates: http://stackoverflow.com/questions/8802734/sorting-and-removing-duplicate-words-in-a-line
  DOM_LIST=$(echo "$DOM_LIST" | xargs -n1 | sort -u | xargs)
  echo "DOM_LIST=[$DOM_LIST]"
  if [ -e /etc/haproxy/ssl/letsencrypt.pem ]; then
    # Generate list of Domains in Certificado, same formatating
    DOM_CERT=$(openssl x509 -in /etc/haproxy/ssl/letsencrypt.pem -text | grep DNS | xargs -n1 | tr -d "DNS:" | tr -d "," | sort -u | xargs)
    [ -n "$DOM_CERT" ] && echo "DOM_CERT=[$DOM_CERT]"
    # Get the validity date of Certificado
    DATE_CERT=$(openssl x509 -in /etc/haproxy/ssl/letsencrypt.pem -text | grep "Not After" | sed -n 's/\s*Not After : \(.*\)/\1/p')
    # Calculate the number of days remaining
    DAYS=$(( ($(date -d "$DATE_CERT" +%s) - $(date +%s)) / 86400 ))
    echo "There already exists an installed certificate, valid for: $DAYS days"
  else
    echo "No certificate found"
    DOM_CERT=""
  fi
  # Generate information needed to Generate/Renew Certificate
  DOM1=""
  for DOM in $DOM_LIST; do
    NEW_DOMAINS+=" -d $DOM"
    [ -z "$DOM1" ] && DOM1="$DOM" # Save first on the list
  done
  # Path to where the Certificado is saved
  LE_CERT_PATH="/etc/letsencrypt/live/$DOM1"
  # Path to the letsencrypt-auto tool
  LE_TOOL=/opt/letsencrypt/letsencrypt-auto
  [ "$LE_TEST" == "Y" ] && LE_TOOL+=" --test-cert"
  # Now we can test if a Certificate will be made...
  if [ "$DOM_LIST" != "$DOM_CERT" ]; then
    echo -e "\n         ┌──────────────────────────────────────┐"
    echo -e   "         │     Gerating SSL Certificate ...     │"
    echo -e   "         └──────────────────────────────────────┘\n"
#set -x
    echo "NEW_DOMAINS=[$NEW_DOMAINS]"
    # Remove data from previous certificates, else old domains will keep renewing
    rm -rf /etc/letsencrypt/archive/*
    rm -rf /etc/letsencrypt/live/*
    rm -rf /etc/letsencrypt/renewal/*
    # Create or renew certificate for the domain(s) supplied for this tool
    # Use "tls-sni-01" for port 443
    # Use "--test-cert" for testing (staging)
    $LE_TOOL --agree-tos --renew-by-default --email "$EMAIL_ADMIN" \
             --standalone --standalone-supported-challenges        \
             http-01 --http-01-port 9999 certonly $NEW_DOMAINS 2>&1 | tee /root/certoutput.txt
    # Limpa Arquivo
    cat certoutput.txt | sed 's/.*\(IMPORTANT NOTES:\)/\1/' | sed -n '/IMPORTANT NOTES:/{h;${x;p;};d;};H;${x;p;}' >/root/certoutput2.txt
    MSG="Your new Certificate was generated for the domains:\n$(echo "$DOM_LIST" | xargs -n1)\n"
    MSG+="====================\n$(cat /root/certoutput2.txt)\n===================="
    if [ $? -eq 0 ]; then
      echo -e "$MSG" | tr -cd '\11\12\15\40-\176' | mail -s "Certificate generated for [$(hostname)] - OK" $EMAIL_ADMIN
      LE_CURRENT_CERT="$(cat /root/certoutput.txt | sed -n 's/.*\/etc\/letsencrypt\/live\/\(.*\)\/fullchain.pem.*/\1/p')"
      if [ "$DOM1" != "$LE_CURRENT_CERT" ]; then
        echo "First domain : $DOM1"
        echo "Reported in Cert: $LE_CURRENT_CERT"
        echo "ERRO: Certificate was not saved in the expected directory"
        read -p "Press <Enter> to continue" A
        # abort to keepprevious configuration
        exit 1
      fi
      # Cat the certificate chain and the private key together for haproxy
      # Cert is saved with the name of the first certificate (alphabetical order...)
      rm -rf /etc/haproxy/ssl/*
      cat $LE_CERT_PATH/{fullchain.pem,privkey.pem} > /etc/haproxy/ssl/letsencrypt.pem # | sed -n 's/\(.*\)-.*/\1/p'
      # Save path for future use, only the last one is interesting
      echo "LE_CERT_PATH=$LE_CERT_PATH" > /script/info/letsencrypt.var
      # Reload the haproxy daemon to activate the cert
      service haproxy reload
    else
      echo -e "$MSG" | tr -cd '\11\12\15\40-\176' | mail -s "ERROR gerating certificate for [$(hostname)]" $EMAIL_ADMIN
      echo "Error geranting Certificate"
    fi
  elif [ $DAYS -lt $LE_VAL ]; then
    echo -e "\n         ┌────────────────────────────────────────┐"
    echo -e   "         │      Renewing SSL Certificate ...      │"
    echo -e   "         └────────────────────────────────────────┘\n"
#set -x
    # Renew with the same automated system
    # Use "--test-cert" for testing (staging)
    # Use "--renew-by-default" to force renewal
    $LE_TOOL --renew-by-default --no-self-upgrade --email "$EMAIL_ADMIN" renew 2>&1 | tee /root/certoutput.txt
    # Clear file
    cat certoutput.txt | sed 's/.*\(IMPORTANT NOTES:\)/\1/' | sed -n '/IMPORTANT NOTES:/{h;${x;p;};d;};H;${x;p;}' >/root/certoutput2.txt
    MSG="Your Certificate was RENEWED for the domains:\n$(echo "$DOM_LIST" | xargs -n1)\n"
    MSG+="====================\n$(cat /root/certoutput2.txt)\n===================="
    if [ $? -eq 0 ] && ! grep "could not be renewed" /root/certoutput.txt ; then
      echo -e "$MSG" | tr -cd '\11\12\15\40-\176' | mail -s "Certificate RENEWED for [$(hostname)] - OK" $EMAIL_ADMIN
      # Path do Certificado, informado pelo Let's encrypt
      LE_CURRENT_CERT=$(cat /root/certoutput.txt | sed -n -e '/have been renewed/,$p' | sed -n 's/.*\/etc\/letsencrypt\/live\/\(.*\)\/fullchain.pem.*/\1/p')
      # Cat the certificate chain and the private key together for haproxy
      # Fica guardado com o nome do primeiro certificado (ordem alfabetica...)
      rm -rf /etc/haproxy/ssl/*
      cat $LE_CERT_PATH/{fullchain.pem,privkey.pem} > /etc/haproxy/ssl/letsencrypt.pem
      # Guarda Path para uso futuro, só o último é válido
      echo "LE_CERT_PATH=$LE_CERT_PATH" > /script/info/letsencrypt.var
      # Reload the haproxy daemon to activate the cert
      service haproxy reload
    else
      echo -e "$MSG" | tr -cd '\11\12\15\40-\176' | mail -s "ERROR renewing certificate for [$(hostname)]" $EMAIL_ADMIN
      echo "Error renewing Certificate"
    fi
  else
    echo "Your certificate does not need to be renewed"
  fi
}

#=======================================================================
# Get the newest version of HAproxy 1.6
# http://www.lua.org/manual/
function GetVerHaproxy(){
  # Use WGET with "--no-dns-cache -4" for faster connection
  local SRC=$(wget --quiet --no-dns-cache -4 $HAPROXY_DL/ -O - | \
              sed -n 's/.*\(haproxy-1\.6\.[0-9]\+\)\.tar\.gz<.*/\1/p' | sort | tail -n 1)
  echo "$SRC"
}

#-----------------------------------------------------------------------
# Get the newest version of Lua 5.3
function GetVerLua(){
  # Use WGET with "--no-dns-cache -4" for faster connection
  local SRC=$(wget --quiet --no-dns-cache -4 $LUA_DL/ -O - | \
              sed -n 's/.*\(lua-5\.3\.[0-9]\+\)\.tar\.gz<.*/\1/p' | sort | tail -n 1)
  echo "$SRC"
}

#-----------------------------------------------------------------------
# Install HAproxy 1.6 with LUA
# http://blog.haproxy.com/2015/10/14/whats-new-in-haproxy-1-6/
# Check compiling options: http://stackoverflow.com/questions/34986893/getting-error-as-unknown-keyword-ssl-in-haproxy-configuration-file
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
  # create diretories for instalation
  mkdir -p  $INSTALL_DIR
  pushd $INSTALL_DIR

  local LUA_CUR_VER=$(lua -v | sed -n 's/.* \([0-9]*\.[0-9]*\).*/\1/p')
  if [ "$LUA_CUR_VER" != "5.3" ]; then
    # Load last version of Lua 5.3
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
    # Load last version of HAproxy 1.6
    HAPROXY_VER=$(GetVerHaproxy)
    # download and expand
    rm -f $HAPROXY_VER.tar.gz
    wget $HAPROXY_DL/$HAPROXY_VER.tar.gz
    tar xf $HAPROXY_VER.tar.gz
    cd $HAPROXY_VER
    make TARGET=linux2628 CPU=x8664 USE_OPENSSL=1 USE_ZLIB=1 USE_PCRE=1 USE_LUA=yes LDFLAGS=-ldl
    make install
    # Verify compiling options
    ./haproxy -vv > /root/haproxy.opt.txt
    # Create a link, some scripts use the binário at /usr/sbin
    ln -sf /usr/local/sbin/haproxy /usr/sbin/haproxy

    # copy o init.d and set execution rigths (use same as other files).
    # TODO: use uptart/systemd CentOS/Ubuntu, test $DISTRO_NAME
    cp examples/haproxy.init /etc/init.d/haproxy
    chmod 755 /etc/init.d/haproxy
    # copy error files
    mkdir -p /etc/haproxy/errors
    cp examples/errorfiles/* /etc/haproxy/errors
    chmod 600 /etc/haproxy/errors
    # diretory for certificates
    mkdir -p /etc/haproxy/ssl

    # add groupo, user and diretory for haproxy, needed for CHROOT
    id -g haproxy &>/dev/null || groupadd -r haproxy
    id -u haproxy &>/dev/null || useradd -g haproxy -s /usr/sbin/nologin -r haproxy
    # creates diretories in etc and stats.
    mkdir -p /var/lib/haproxy
    touch /var/lib/haproxy/stats
    # Configure o rsyslog to accept port UDP:514, needed for CHROOT
    [ ! -e /etc/rsyslog.conf.orig ] && cp /etc/rsyslog.conf /etc/rsyslog.conf.orig
    sed -i '/\$ModLoad imudp/s/#//;' /etc/rsyslog.conf
    sed -i '/\$UDPServerRun 514/s/#//;' /etc/rsyslog.conf
    service rsyslog reload

    # configure rsyslog for haproxy
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
    # Configure Logrotate (see in monit.sh)
    ARQ="/etc/logrotate.d/haproxy"
    if [ ! -e $ARQ ]; then
      cat <<- EOF > $ARQ
			##################################################
			##  Logrotate for haproxy
			##################################################
			##  After creation, this file is never changed

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
  # Back and remove temporary diretory
  popd
  rm -rf $INSTALL_DIR
}

#-----------------------------------------------------------------------
# Reconfigure HAproxy
# Configurations from: https://mozilla.github.io/server-side-tls/ssl-config-generator/
function HaproxyReconfig(){
  local ARK APP U USR URI URIS DOM DIR PORT HTTP HTTPS NACL APP_LIST TMP_FRONT
  local SORT_LIST=""
  local HTTP_FRONT=""
  local HTTPS_FRONT=""
  local HTTP_BAK=""
  local HAS_HTTP="N"
  local HAS_SSL="N"
  local ARQ="/etc/haproxy/haproxy.cfg"
  # Create list of Applications, Linux users
  APP_LIST=$(GetAppList)
  echo "APP_LIST=[$APP_LIST]"
  # Scan all Application configuration files
  for APP in $APP_LIST; do
    if [ -e "/script/info/hap-$APP.var" ]; then
      # echo "AppConfig found: $APP"
      # cat "/script/info/hap-$APP.var"
      # Read config for each Application
      GetSingleAppVars $APP
      if [ -n "$HAPP_URIS" ]; then
        # Create a List with alls information of an Application
        for URI in $HAPP_URIS; do
          DOM="$(echo "$URI" | sed -n 's@\([^\/]*\)\/\?.*@\1@p')"
          DIR="$(echo "$URI" | sed -n 's@[^\/]*\(.*\)@\1@p')"
          # Create the ACL list for sort
          SORT_LIST+="$(( 1000- ${#DOM} ))	\"$DOM\"	$(( 1000- ${#DIR} ))	\"$DIR\"	$APP	$HAPP_PORT	$HAPP_HTTP	$HAPP_HTTPS\n"
        done
        # Flags for all Applications
        [ "$HAPP_HTTP"  == "Y" ] && HAS_HTTP="Y"
        [ "$HAPP_HTTPS" == "Y" ] && HAS_SSL="Y"
        # Create all Backends
        HTTP_BAK+="\n#{NFAS HTTP-BAK: $APP}\n"
        HTTP_BAK+="backend http-$APP\n"
        HTTP_BAK+="  option forwardfor  # Original IP address\n"
        # https://www.digitalocean.com/community/tutorials/how-to-protect-your-server-against-the-httpoxy-vulnerability?utm_medium=newsletter&utm_source=newsletter&utm_campaign=072116
        HTTP_BAK+="  http-request del-header Proxy  # HTTPoxy Vulnerability\n"
        HTTP_BAK+="  http-response set-header X-Frame-Options SAMEORIGIN  # no clickjacking\n"
        if [ "$HAPP_HTTP" == "N" ] && [ "$HAPP_HTTPS" == "Y" ]; then
          # Add HSTS, only if has to redirect. Has to be > 6 months, 16000000
          HTTP_BAK+="  http-response set-header Strict-Transport-Security \"max-age=16000000; includeSubDomains; preload;\"\n"
        fi
        HTTP_BAK+="  server srv-$APP 127.0.0.1:$HAPP_PORT check\n"
      fi # Exist URIs
    fi # Exit config file
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
      # Cotains only domain, now can come with port number, as of RFC2616
      # https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.23
      TMP_FRONT+="  acl host_"$APP"_"$NACL" req.hdr(host) -m dom -i $DOM\n"
      if [ "$HTTP" == "N" ] && [ "$HTTPS" == "Y" ]; then
        # Precisa redirecionar
        HTTP_FRONT+=$TMP_FRONT
        HTTPS_FRONT+=$TMP_FRONT
        # HTTP does redirect
        HTTP_FRONT+="  use_backend http-redirect if host_"$APP"_"$NACL"\n"
        # HTTPS go to the application
        HTTPS_FRONT+="  use_backend http-$APP if host_"$APP"_"$NACL"\n"
      else
        TMP_FRONT+="  use_backend http-$APP if host_"$APP"_"$NACL"\n"
        # Add frontends, may be only for HTTP or for both
        [ "$HTTP" == "Y" ]  && HTTP_FRONT+=$TMP_FRONT
        [ "$HTTPS" == "Y" ] && HTTPS_FRONT+=$TMP_FRONT
      fi
    else
      if [ -n "$DOM" ]; then
        TMP_FRONT+="  acl host_"$APP"_"$NACL"h req.hdr(host) -m dom -i $DOM\n"
        TMP_FRONT+="  acl host_"$APP"_"$NACL"d path_dir -i $DIR\n"
        if [ "$HTTP" == "N" ] && [ "$HTTPS" == "Y" ]; then
          # Needs to redirect
          HTTP_FRONT+=$TMP_FRONT
          HTTPS_FRONT+=$TMP_FRONT
          # HTTP does redirect
          HTTP_FRONT+="  use_backend http-redirect if host_"$APP"_"$NACL"h host_"$APP"_"$NACL"d\n"
          # HTTPS go to the application
          HTTPS_FRONT+="  use_backend http-$APP if host_"$APP"_"$NACL"h host_"$APP"_"$NACL"d\n"
        else
          TMP_FRONT+="  use_backend http-$APP if host_"$APP"_"$NACL"h host_"$APP"_"$NACL"d\n"
        # Add frontends, may be only for HTTP or for both
        [ "$HTTP" == "Y" ]  && HTTP_FRONT+=$TMP_FRONT
        [ "$HTTPS" == "Y" ] && HTTPS_FRONT+=$TMP_FRONT
        fi
      elif [ "$HTTP" == "Y" ]; then
        # Without domain, direct access. Starts with '/'
        # Needs to use a RegEx to identify access by IP only ("-m ip" did not work)
        # Can only be used with HTTP, TODO: test with IPv6
        HTTP_FRONT+=$TMP_FRONT
        HTTP_FRONT+="  acl host_"$APP"_"$NACL"h req.hdr(host) -m reg ^[0-9\.]*$\n"
        HTTP_FRONT+="  acl host_"$APP"_"$NACL"h req.hdr(host) -i -m reg ^[0-9a-f:]*$\n"
        HTTP_FRONT+="  acl host_"$APP"_"$NACL"d path_dir -i $DIR\n"
        HTTP_FRONT+="  use_backend http-$APP if host_"$APP"_"$NACL"h host_"$APP"_"$NACL"d\n"
      fi
    fi
    # ACL indexer
    NACL=$(( $NACL + 1 ))
  done <<< "$SORT_LIST"
  # echo -e "HTTP_FRONT:\n$HTTP_FRONT"
  # echo -e "HTTPS_FRONT:\n$HTTPS_FRONT"
  # Create the configuration file
  ARQ="/etc/haproxy/haproxy.cfg"
  echo "##################################################"               >  $ARQ
  echo "##  HAPROXY: main configuration file"                             >> $ARQ
  echo "##################################################"               >> $ARQ
  echo "##  Do not edit, this file will be recreated"                     >> $ARQ
  echo ""                                                                 >> $ARQ
  echo "global"                                                           >> $ARQ
  echo "  maxconn 20000"                                                  >> $ARQ
  echo "  log "\${LOCAL_SYSLOG}:514" local0 notice alert # notice/info/debug" >> $ARQ
  echo "  user   haproxy"                                                 >> $ARQ
  echo "  group  haproxy"                                                 >> $ARQ
  echo "  chroot /var/lib/haproxy"                                        >> $ARQ
  if [ "$HAS_SSL" == "Y" ]; then
    # Configurations for each level of cryptography
    if [ "$HAP_CRYPT_LEVEL" == "1" ]; then
      echo -e "$HAP_GLOBAL_N1"                                            >> $ARQ
    elif [ "$HAP_CRYPT_LEVEL" == "3" ]; then
      echo -e "$HAP_GLOBAL_N3"                                            >> $ARQ
    else
      # default is Intermediate level
      echo -e "$HAP_GLOBAL_N2"                                            >> $ARQ
    fi
  fi
  echo ""                                                                 >> $ARQ
  echo "defaults"                                                         >> $ARQ
  echo "  mode http"                                                      >> $ARQ
  echo "  option forwardfor"                                              >> $ARQ
  # Try alternate server (if using load balance) in case of fault
  echo "  retries  3"                                                     >> $ARQ
  echo "  option  redispatch"                                             >> $ARQ
  # Needed to reevaluate tests in Headers every time
  echo "  option http-server-close"                                       >> $ARQ
  # recommended timeouts: http://cbonte.github.io/haproxy-dconv/configuration-1.6.html#timeout%20tunnel
  # tunnel is for Websockets
  echo "  timeout connect      5s  # from HAproxy to Server"              >> $ARQ
  echo "  timeout client       30s # if client doesn't answer"            >> $ARQ
  echo "  timeout server       30s # if server doesn't answer"            >> $ARQ
  echo "  timeout client-fin   30s # for badly closed connections"        >> $ARQ
  echo "  timeout tunnel       1h  # Used for WebSockets"                 >> $ARQ
  echo "  timeout http-request 5s  # SlowLorris"                          >> $ARQ
  # Custom Log format: http://cbonte.github.io/haproxy-dconv/1.6/configuration.html#8.2.4
  # Configure to show ssl_version (ex: TLSv1) and ssl_ciphers (ex: AES-SHA), at the end. Example:
  # Connect from 187.101.86.93:27554 (www-https) "GET / HTTP/1.1" TLSv1.1 AES128-SHA
  # default is: Connect from 187.101.86.93:3641 to 172.31.59.149:443 (www-https/HTTP)
  echo "  log-format Connect\ from\ %ci:%cp\ (%f)\ %{+Q}r\ %hrl\ %sslv\ %sslc">> $ARQ
  echo "  log global"                                                     >> $ARQ
  # Configure email alerts: https://www.haproxy.com/doc/hapee/1.5r2/traffic_management/alerting.html
  # level=notice: to send if server UP and DOWN
  echo "  email-alert mailers postfix-local"                              >> $ARQ
  echo "  email-alert level notice"                                       >> $ARQ
  echo "  email-alert from HAproxy@$HOSTNAME_INFO"                        >> $ARQ
  echo "  email-alert to $EMAIL_ADMIN"                                    >> $ARQ
  echo ""                                                                 >> $ARQ
  echo "frontend www-http"                                                >> $ARQ
  echo "  bind :80"                                                       >> $ARQ
  # Need command to capture the Request-Host for showing in the log
  echo "  capture request header Host len 250"                            >> $ARQ
  if [ "$HAS_SSL" == "Y" ]; then
    echo "  #{NFAS HTTPS-FRONT: Automação do Lets Encrypt}"               >> $ARQ
    echo "  acl letsencrypt-request path_beg -i /.well-known/acme-challenge/">> $ARQ
    echo "  use_backend letsencrypt if letsencrypt-request"               >> $ARQ
  fi
  # FrontEnd configurations for each application
  echo -e "$HTTP_FRONT"                                                   >> $ARQ
  # Has no default site
  # echo "  default_backend http-backend"                                 >> $ARQ
  if [ "$HAS_SSL" == "Y" ]; then
    # Fornt-End for Lets Encrypt HTTPS
    echo "frontend www-https"                                             >> $ARQ
    if [ -e /etc/haproxy/ssl/letsencrypt.pem ]; then
      # Already exists a certificate, current or previous (to be updated)
      if [ "$HAP_CRYPT_LEVEL" == "1" ]; then
        echo -e "$HAP_HTTPS_N1"                                           >> $ARQ
      elif [ "$HAP_CRYPT_LEVEL" == "3" ]; then
        echo -e "$HAP_HTTPS_N3"                                           >> $ARQ
      else
        # default level is Intermediate
        echo -e "$HAP_HTTPS_N2"                                           >> $ARQ
      fi
      # Needs command to capture Request-Host to show in log
      echo "  capture request header Host len 250"                        >> $ARQ
      # Header changes must come first
      echo -e "  http-request set-header X-Forwarded-Proto https"         >> $ARQ
      # If in port 443 but is not encrypted, redirect. "code 301" is: moved permanently
      echo -e "  redirect scheme https if !{ ssl_fc }"                    >> $ARQ
      # FrontEnd configurations for each application
      echo -e "$HTTPS_FRONT"                                              >> $ARQ
    else
      # if ther is no certificate
      echo "  bind :443"                                                  >> $ARQ
      # Needs command to capture Request-Host to show in log
      echo "  capture request header Host len 250"                        >> $ARQ
    fi
  else
    echo "#{NFAS: No Application has SSL}"                                >> $ARQ
  fi
  # Create BackEnds
  echo -e "$HTTP_BAK"                                                     >> $ARQ
  if [ "$HAS_SSL" == "Y" ]; then
    # Backend for redirecting HTTP=>HTTPS in the correct sequence
    echo "#{NFAS HTTPS-BAK: Redirects HTTP}"                              >> $ARQ
    echo "backend http-redirect"                                          >> $ARQ
    echo "  redirect scheme https"                                        >> $ARQ
    # Last is Backend for Lets encrypt
    echo ""                                                               >> $ARQ
    echo "#{NFAS HTTPS-BAK: Lets Encrypt automation}"                     >> $ARQ
    echo "backend letsencrypt"                                            >> $ARQ
    echo "  server letsencrypt 127.0.0.1:9999"                            >> $ARQ
  fi
  # Has to setup Emailserver as well
  echo ""                                                                 >> $ARQ
  echo "#{NFAS: Local email server}"                                      >> $ARQ
  echo "mailers postfix-local"                                            >> $ARQ
  echo "  mailer smtp1 127.0.0.1:25"                                      >> $ARQ
  # There is no default site
  # echo "backend http-backend"                                           >> $ARQ
  # Configure restricted access
  chmod 600 $ARQ
  # Verify configuration file and save for debug
  haproxy -c -q -V -f /etc/haproxy/haproxy.cfg >/root/haproxy.check
  # install and  start service
  if [ "$CMD" == "--first" ]; then
    # Needs to install and start the serviçe
    if [ "$DISTRO_NAME_VERS" == "CentOS 6" ]; then
      # using init
      chkconfig --add haproxy
      chkconfig --level 345 haproxy on
      service haproxy start
    fi
  else
    # restart the service
    service haproxy restart
  fi
  HAP_NEW_CONF="N"
}

#-----------------------------------------------------------------------
# Read all HAproxy config if exits
# Configure default values
function ReadHaproxyVars(){
  # Erase any previous variable and create competiblity
  HAP_CRYPT_LEVEL="2"
  HAP_NEW_CONF="N"
  HAP_NXT_PORT="3000"
  if [ -e $VAR_FILE ]; then
    # Read exiting file
    . $VAR_FILE
  fi
}
#-----------------------------------------------------------------------
# Save config variables
# NOTE: in this module, config setings are allways read from the real config file
# these variables are saved only for future export system
function SaveHaproxyVars(){
  echo "HAP_CRYPT_LEVEL=\"$HAP_CRYPT_LEVEL\""                         2>/dev/null >  $VAR_FILE
  echo "HAP_NEW_CONF=\"$HAP_NEW_CONF\""                               2>/dev/null >> $VAR_FILE
  echo "HAP_NXT_PORT=\"$HAP_NXT_PORT\""                               2>/dev/null >> $VAR_FILE
}

#=======================================================================
# main()

# Rad variables and set defaults
ReadHaproxyVars
TITLE="NFAS - HAproxy Configuration"

if [ "$CMD" == "--first" ]; then
  # Install HAproxy, does not configure nor inicialize
  HaproxyInstall
  # Instal Let's Encrypt scripts and dependencies
  LetsEncryptInstall
  # Read the wanted security level, kept in $HAP_CRYPT_LEVEL
  GetHaproxyLevel
  # Create a basic empty configuration, Strat service
  HaproxyReconfig

elif [ "$CMD" == "--appconn" ]; then
  #-----------------------------------------------------------------------
  # Get Connection type for one Application
  HAPP=$2
  GetAppConnType

elif [ "$CMD" == "--appuris" ]; then
  #-----------------------------------------------------------------------
  # Edit list of URIs
  HAPP=$2
  GetAppUriList

elif [ "$CMD" == "--newapp" ]; then
  #-----------------------------------------------------------------------
  # Create default configuration for a new Application
  HAPP=$2
  # Read possibly existing variables
  GetSingleAppVars $HAPP
  # create defaults, config and save, uses $HAPP for identification
  ConfigSingleApp
  # Configuration has been changed, mark to reconfigure
  HAP_NEW_CONF="Y"

elif [ "$CMD" == "--ssl" ]; then
  #-----------------------------------------------------------------------
  # Read the wanted security level, kept in $HAP_CRYPT_LEVEL
  GetHaproxyLevel

elif [ "$CMD" == "--hostname" ] || [ "$CMD" == "--email" ]; then
  #-----------------------------------------------------------------------
  # Recreate /etc/haproxy/haproxy.conf with new data
  HaproxyReconfig

elif [ "$CMD" == "--reconfig" ]; then
  #-----------------------------------------------------------------------
  # Reconfigure HAproxy if anythin has chaged
  echo "---------------------"
  echo " HAproxy RECONFIGURE "
  echo "---------------------"
  # Make a preliminary setup, needed to create a certificate
  HaproxyReconfig
  # If in VirtualBox it is impossible to autenticate
  if [ "$IS_VIRTUALBOX" != "Y" ]; then
    # Get the Certificate, if needed
    GetCertificate
    # Rebuild configuration for HTTP(S), portas 80 e 443
    HaproxyReconfig
  fi

elif [ "$CMD" == "--certonly" ]; then
  #-----------------------------------------------------------------------
  # Should be called from CRON, comes with no environment
  # Python Bombs if HOME ans PWD are different!
  SHELL=/bin/bash
  PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
  HOME=/root
  cd /root
  # Create a timestamp in the log
  date
  # Get the Certificate, if needed
  GetCertificate

# elif [ "$CMD" == "--app" ]; then
#  #-----------------------------------------------------------------------
#  # Read configuration for one Application
#  EditAppConfig
#  if [ $? == 0 ]; then
#    # Configuration was edited and accepted
#    HAP_NEW_CONF="Y"
#  fi

fi
# Save Variables
SaveHaproxyVars

#=======================================================================
