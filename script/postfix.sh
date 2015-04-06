#!/bin/bash
set -x

# Script para (re)configurar o envio de Email usando o POSTFIX
# O mesmo Script é usado para a primeira vez e para alterar a configuração
# Chamada: "/script/postfix.sh <cmd>"
# <cmd>: --first     durante primeira instalação, chamada pelo email.sh
#        --email     alteradas configurações de email, só se alteração posterior
#        --hostname  quando foi alterado hostname, só se alteração posterior
#
# usa as variaveis armazenadas em:
# /script/info/hostname.var
# /script/info/email.var
#
# https://www.linode.com/docs/email/postfix/postfix-smtp-debian7
# http://help.mandrill.com/entries/23060367-Can-I-configure-Postfix-to-send-through-Mandrill-
# http://wiki.centos.org/HowTos/postfix_sasl_relayhost

#-----------------------------------------------------------------------
# Processa a linha de comando
CMD=$1
# Lê dados anteriores
. /script/info/hostname.var
. /script/info/email.var

#-----------------------------------------------------------------------
# Instala e faz cópia da configuração original

yum -y install mailx cyrus-sasl-plain postfix-perl-scripts  # postfix já vem instalado
if [ ! -e /etc/postfix/main.cf.orig ]; then
  cp -a /etc/postfix/main.cf /etc/postfix/main.cf.orig
fi
# Para Ubuntu: apt-get install libsasl2-modules

#-----------------------------------------------------------------------
# Cria novo arquivo de configuração

# Cria arquivos com a senha
echo "[$EMAIL_SMTP_URL]:$EMAIL_SMTP_PORT $EMAIL_USER_ID:$EMAIL_USER_PASSWD" > /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
# segurança
chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

CFG=/etc/postfix/main.cf
# não pode ter [ ]: http://stackoverflow.com/questions/11287861/how-to-check-if-a-file-contains-a-specific-string-using-bash
if ! grep -q "Fim do arquivo" $CFG; then
  echo -e "\n\n#=========================================================="           >> $CFG
  echo -e   "\n# Fim do arquivo original"                                             >> $CFG
  echo -e   "\n# mas as configurações já existentes foram alteradas acima deste ponto" >> $CFG
  echo -e   "\n#=========================================================="           >> $CFG
fi

# Configura o POSSTFIX usando comando próprio de edição
# SMTP relay host, vai usar para encontrar a senha
postconf -e relayhost=[$EMAIL_SMTP_URL]:$EMAIL_SMTP_PORT
# sistema de autenticação SASL
postconf -e smtp_sasl_auth_enable=yes
postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
postconf -e smtp_sasl_security_options=noanonymous
# configurações recomendadas mas que n~ao foi detectado problema
postconf -e smtp_cname_overrides_servername=no
postconf -e smtp_sasl_mechanism_filter=login
# Garante que só recebe da porta local
postconf -e inet_interfaces=127.0.0.1
# Testa se usa StartTLS
if [ "$EMAIL_SMTP_STARTTLS" == "Y" ]; then
  postconf -e smtp_use_tls=yes
else
  postconf -e smtp_use_tls=no
fi

#-----------------------------------------------------------------------
# altera identificação dos remetentes
# Configura Aliases dos unuários
# Todos os Usuários no grupo MAIL

# Campo chamado "finger" fica no arquivo /etc/passwd
chfn -f "root@$(hostname -s)" root                                  >/dev/null
# Loop para todos os usuários
for USR in $(ls /home); do
  # campo "finger
  chfn -f "$USR@$(hostname -s)" $USR                                >/dev/null
  # acrescenta usuários ao gripo MAIL para poderem mandar Email
  usermod -a -G mail $USR
done

#-----------------------------------------------------------------------
