#!/bin/bash
# set -x

# # Script for installing and configuring GIT
# Usage: /script/prog-git.sh <cmd>
# <cmd>: --first       First install
#        --hostname    Hostname changed (used by git)
#        --email       Email changed (used by git)
#        <sem nada>    Do noting!

#=======================================================================
# Process command line
CMD=$1
# Read previous configurations if they exist
. /script/info/hostname.var
. /script/info/email.var
VAR_FILE="/script/info/progs.var"
[ -e $VAR_FILE ] && . $VAR_FILE

#-----------------------------------------------------------------------
# GIt configuration function
# only sets global email and user (-hostname)
function SetupGit(){
  local MSG
  # Set same email as system
  git config --global user.email "$EMAIL_ADMIN"
  # Set user same as host name by default
  git config --global user.name "$HOSTNAME_INFO"
  # Forces Git to create files with group access
  git config --global core.sharedRepository 0660
  # Information only message
     MSG=" Instaled compilation utilities: GCC, Make, etc.."
  MSG+="\n\nGIT was installed and configured:"
    MSG+="\n  Name and Email globals same as administrator's,"
    MSG+="\n  New file creation with mask 660 for group access."
  whiptail --title "$TITLE" --msgbox "$MSG" 13 70
}

#-----------------------------------------------------------------------

TITLE="NFAS - Installing and Configuring GIT"
if [ "$CMD" == "--first" ]; then
  #--- Configure o git
  SetupGit

#-----------------------------------------------------------------------
elif [ "$CMD" == "--hostname" ]; then
   # Re-configure hostname as default name
  git config --global user.name "$HOSTNAME_INFO"

#-----------------------------------------------------------------------
elif [ "$CMD" == "--email" ]; then
  # Re-configura email the same as sistem's
  git config --global user.email "$EMAIL_ADMIN"

#-----------------------------------------------------------------------
else
  #--- do nothing!

fi
