#!/bin/bash
set -x

#### ATENÇÃO ### Este script está obsoleto e não é mais usado
# Está sendo mantido aqui apenas porque pode ser útil para alguém

# Script para (re)configurar o envio de Email usando o SSMTP
# O mesmo Script é usado para a primeira vez e para alterar a configuração
# Chamada: "/script/ssmtp.sh <cmd>"
# <cmd>: --first     durante primeira instalação, chamada pelo email.sh
#        --email     alteradas configurações de email, só se alteração posterior
#        --hostname  quando foi alterado hostname, só se alteração posterior
#
# usa as variaveis armazenadas em:
# /script/info/hostname.var
# /script/info/email.var
#
# man: http://linux.die.net/man/8/ssmtp  http://linux.die.net/man/5/ssmtp.conf

#-----------------------------------------------------------------------
# Processa a linha de comando
CMD=$1
[ "$1" == "--first" ] && FIRST="Y" || FIRST="N"  # Versão compacta do if/else
# Lê dados anteriores
. /script/info/hostname.var
. /script/info/email.var

#-----------------------------------------------------------------------
# Instala e faz cópia da configuração original

yum -y install ssmtp mailx
if [ ! -e /etc/ssmtp/ssmtp.conf.orig ]; then
  cp -a /etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf.orig
  cp -a /etc/ssmtp/revaliases /etc/ssmtp/revaliases.orig
fi

# configura ssmtp substituindo sendmail, será usado pelo comando mail
# http://archive09.linux.com/feature/132006
if [ ! -e "/usr/sbin/sendmail.orig" ]; then
  mv /usr/sbin/sendmail /usr/sbin/sendmail.orig
  ln -s /usr/sbin/ssmtp /usr/sbin/sendmail
fi

#-----------------------------------------------------------------------
# Cria novo arquivo de configuração
# https://wiki.archlinux.org/index.php/SSMTP

CFG=/etc/ssmtp/ssmtp.conf
echo -e "\n# Usuário root recebe todos os Email"               > $CFG
echo -e "root=$EMAIL_ADMIN"                                   >> $CFG
echo -e "\n# Servidor de Email e porta"                       >> $CFG
echo -e "mailhub=$EMAIL_SMTP_URL:$EMAIL_SMTP_PORT"            >> $CFG
echo -e "\n# TLS e StartTLS se procisar"                      >> $CFG
if [ "$EMAIL_SMTP_STARTTLS" == "Y" ]; then
  echo -e "UseTLS=Yes"                                        >> $CFG
  echo -e "UseSTARTTLS=Yes"                                   >> $CFG
fi
echo -e "\n# Usuário e Senha da conta no serviror de Email"   >> $CFG
echo -e "AuthUser=$EMAIL_USER_ID"                             >> $CFG
echo -e "AuthPass=$EMAIL_USER_PASSWD"                         >> $CFG
echo -e "# Método de autenticação preferencial (+seguro)"     >> $CFG
echo -e "AuthMethod=LOGIN"                                    >> $CFG
echo -e "\n# hostname desta máquina"                          >> $CFG
echo -e "hostname=$HOSTNAME_INFO"                             >> $CFG
echo -e "\n# Não permite troca do Remetente da mensagem"      >> $CFG
echo -e "FromLineOverride=no"                                 >> $CFG

# Precisa proteger a senha do Email
# https://wiki.archlinux.org/index.php/SSMTP#Security
SSMTP_BIN=$(which ssmtp)                       # Lugar do binário pode variar
[ "$CMD" == "--first" ] && groupadd -r ssmtp   # Cria Grupo de sistema (número baixo), só primeira vez
chown :ssmtp /etc/ssmtp/ssmtp.conf             # Muda grupo do arquivo de configuração
chown :ssmtp $SSMTP_BIN                        # Muda grupo do binário
chmod 640 /etc/ssmtp/ssmtp.conf                # só root e o grupo podem ter acesso ao grupo
chmod g+s $SSMTP_BIN                           # Seta o SGID para acessar dados do grupo

#-----------------------------------------------------------------------
# altera identificação dos remetentes
# Configura Aliases do SSMTP
# Todos os Usuários no grupo MAIL

# Arquivo /etc/ssmtp/revaliases
echo "root:root@$HOSTNAME_INFO:$EMAIL_SMTP_URL:$EMAIL_SMTP_PORT"    >/etc/ssmtp/revaliases
# Campo chamado "finger" fica no arquivo /etc/passwd
chfn -f "root@$(hostname -s)" root                                  >/dev/null
# Loop para todos os usuários
for USR in $(ls /home); do
  # configura ALIASES no ssmtp
  echo "$USR:$USR@$HOSTNAME_INFO:$EMAIL_SMTP_URL:$EMAIL_SMTP_PORT" >>/etc/ssmtp/revaliases
  # campo "finger
  chfn -f "$USR@$(hostname -s)" $USR                                >/dev/null
  # acrescenta usuários ao gripo MAIL para poderem mandar Email
  usermod -a -G mail $USR
done

#-----------------------------------------------------------------------
