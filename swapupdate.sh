#!/bin/bash
#this script is run via cron and checks for updates to swapwatch
#unless the conf says not to
swapURL="http://DOMAIN.com/monitoring/swapwatch.sh"
swapupdateURL="http://DOMAIN.com/monitoring/swapupdate.sh"
APPDIR="/usr/local/sw/apps/swapwatch"
TMPDIR="/usr/local/sw/temp"
LOGDIR="/usr/local/sw/logs"
. /usr/local/sw/configs/swapwatch/swapwatch.conf

################################################################################
#if we are allowed to update
   
if [ $update = "yes" ]
then
  #update swapwatch.sh
  wget -O "$TMPDIR/swapwatch.tmp" $swapURL
  #only overwrite if the dl worked
  if [ "$?" -eq 0 ]
  then 
    #just overwrite... probably with identical data. that's fine
    mv -f "$TMPDIR/swapwatch.tmp" "$APPDIR/swapwatch.sh"
    chmod +x "$APPDIR/swapwatch.sh"
  fi
  #update swapupdate.sh
  wget -O "$TMPDIR/swapupdate.tmp" $swapupdateURL
  if [ "$?" -eq 0 ]
  then
    mv -f "$TMPDIR/swapupdate.tmp" "$APPDIR/swapupdate.sh"
    chmod +x "$APPDIR/swapupdate.sh"
    #log
    echo "[ $(date +%c) ] swapwatch checked for updates" >> $LOGDIR/swapwatch.log
  else
    echo "[ $(date +%c) ] swapwatch update failed" >> $LOGDIR/swapwatch.log
  fi

fi

################################################################################
