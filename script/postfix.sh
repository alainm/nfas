#!/bin/bash
# set -x

# Script para (re)configurar o envio de Email usando o POSTFIX
# O mesmo Script é usado para a primeira vez e para alterar a configuração
# Chamada: "/script/postfix.sh <cmd>"
# <cmd>: --first          durante primeira instalação, depois de hostname.sh, antes de email.sh
#        --email          alteradas configurações de email, só se alteração posterior
#        --hostname       quando foi alterado hostname, só se alteração posterior
#        --newuser <user> quando cria um Aplicativo/usuário
#
# usa as variaveis armazenadas em:
# /script/info/hostname.var
# /script/info/email.var
#
# https://www.linode.com/docs/email/postfix/postfix-smtp-debian7
# http://help.mandrill.com/entries/23060367-Can-I-configure-Postfix-to-send-through-Mandrill-
# http://wiki.centos.org/HowTos/postfix_sasl_relayhost

# Ver fila: mailq, qshape
# Ver email: postcat -q <ID>  # Tem que pegar o ID do comando mailq
# força enviar: postfix flush
# Limpar a fila: postsuper -d ALL
# pacote de utilidades: yum install postfix-perl-scripts
# fila do postfix: https://rtcamp.com/tutorials/mail/postfix-queue/
#                  http://www.tullyrankin.com/managing-the-postfix-queue
# Analise da fila: http://www.postfix.org/QSHAPE_README.html

#-----------------------------------------------------------------------
# Processa a linha de comando
CMD=$1
CMD_USR=$2
# Lê dados anteriores
[ -e /script/info/hostname.var ] && . /script/info/hostname.var
[ -e /script/info/email.var ] &&. /script/info/email.var
# Inclui funções básicas
. /script/functions.sh

#-----------------------------------------------------------------------
# Altera um único usuário, inclusive hostname
# usado quando é criado usuário
# uso: PostfixOneUser <user>
function PostfixOneUser(){
  local TMP_USR=$1
  # campo "finger"
  chfn -f "$TMP_USR@$(hostname -s)" $TMP_USR                >/dev/null
  # ALIAS para envio de email, todos mandam como root
  EditConfColon /etc/aliases $TMP_USR root
  # acrescenta usuários ao grupo MAIL para poderem mandar Email
  usermod -a -G mail $TMP_USR
}

#-----------------------------------------------------------------------
# Altera todos os usuários, inclusive hostname
# Altera identificação dos remetentes e configura Aliases dos usuários
# Todos os Usuários no grupo MAIL
# usado no --first e quando altera hostname
function PostfixAllUsers(){
  local USR
  # para root á separado, usa alias admin
  # Campo chamado "finger" fica no arquivo /etc/passwd
  chfn -f "root@$(hostname -s)" root                        >/dev/null
  # ALIAS para envio de email do root com email real
  EditConfColon /etc/aliases admin root
  # Loop para todos os usuários
  for USR in $(ls /home); do
    PostfixOneUser $USR
  done
}

#-----------------------------------------------------------------------
# main()
# Para Ubuntu: apt-get install libsasl2-modules

# Arquivo de configuração geral
CFG=/etc/postfix/main.cf
# Interpreta comandos de entrada
if [ "$CMD" == "--first" ]; then
  # Cópia da configuração original
  if [ ! -e $CFG.orig ]; then
    cp -a $CFG $CFG.orig
  fi
  # Indicador de alteração da configuração
  # não pode ter [ ]: http://stackoverflow.com/questions/11287861/how-to-check-if-a-file-contains-a-specific-string-using-bash
  if ! grep -q "Fim do arquivo" $CFG; then
    echo -e "\n#====================================================================="   >> $CFG
    echo -e   "# Fim do arquivo original"                                                >> $CFG
    echo -e   "# mas as configurações já existentes foram alteradas acima deste ponto"   >> $CFG
    echo -e   "#=====================================================================\n" >> $CFG
  fi
  # Configura o POSSTFIX usando comando próprio de edição
  # sistema de autenticação SASL
  postconf -e smtp_sasl_auth_enable=yes
  postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
  postconf -e smtp_sasl_security_options=noanonymous
  # configurações recomendadas mas que n~ao foi detectado problema
  postconf -e smtp_cname_overrides_servername=no
  postconf -e smtp_sasl_mechanism_filter=login
  # Garante que só recebe da porta local
  postconf -e inet_interfaces=127.0.0.1
  # SMTP relay host, valor dummy só para configurar como RELAY
  postconf -e relayhost=[smtp.gmail.com]:587
  # Reconfigura root e todos os usuários que já existirem: hostname
  PostfixAllUsers

elif [ "$CMD" == "--email" ]; then
  #-----------------------------------------------------------------------
  # Novos dados de Email: cria arquivos com a senha
  echo "[$EMAIL_SMTP_URL]:$EMAIL_SMTP_PORT $EMAIL_USER_ID:$EMAIL_USER_PASSWD" > /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
  # segurança
  chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
  chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
  # Configura o POSSTFIX usando comando próprio de edição
  # SMTP relay host, vai usar para encontrar a senha
  postconf -e relayhost=[$EMAIL_SMTP_URL]:$EMAIL_SMTP_PORT
  # Testa se usa StartTLS
  if [ "$EMAIL_SMTP_STARTTLS" == "Y" ]; then
    postconf -e smtp_use_tls=yes
  else
    postconf -e smtp_use_tls=no
  fi
  EditConfColon /etc/aliases root $EMAIL_ADMIN
  # Reconfigura root e todos os usuários que já existirem
  PostfixAllUsers

elif [ "$CMD" == "--hostname" ]; then
  #-----------------------------------------------------------------------
  # Reconfigura todos os usuários
  PostfixAllUsers

elif [ "$CMD" == "--newuser" ]; then
  #-----------------------------------------------------------------------
  # Reconfigura um novo usuário
  PostfixOneUser $CMD_USR

fi #if $CMD

# Sempre recarrega todas as configurações
newaliases
service postfix restart

#-----------------------------------------------------------------------
