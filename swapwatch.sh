#!/bin/bash
#version number
#2.0.0
#rewrite by rlong

LOGDIR="/usr/local/sw/logs"
TMPFILE="/usr/local/sw/temp/swapwatch.results"

#Create and clear TMPFILE
touch $TMPFILE
cat /dev/null > $TMPFILE

#check if it's already running
if [ "$(ps ax | grep "$(basename $0)" -c )" -gt 4 ]
then
  exit 1
else

  #Find Current Load
  load=$(awk '{print $1}' /proc/loadavg | cut -d. -f1)

  #Find Current Free Swap
  swap_free=$(grep SwapFree /proc/meminfo | awk '{print $2}')

  #Find Swap Total
  swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')

  #get thresholds
  source /usr/local/lp/configs/swapwatch/swapwatch.conf

  #if that fails (file got rm'd?), use some defaults
  if [ "$?" -ne 0 ]
  then
    loadthreshold=5
    swapthreshold=524288
    contact="support@DOMAIN.com"
  fi

  #check if we should run. either can trigger it
  #make sure server has a swap partition > 0 too
  if  [[ "$load" -gt "$loadthreshold" || ("$swap_free" -lt "$swapthreshold" && "$swap_total" -ne 0) ]]
  then

	#Echo everything into a temp file, to help with ZD compatibility
	echo "Load at $load" >> $TMPFILE
	echo "" >> $TMPFILE
	echo "Swap free at $swap_free" >> $TMPFILE
	echo "" >> $TMPFILE
	echo "Swap threshold is at $swapthreshold" >> $TMPFILE
	echo "" >> $TMPFILE
	echo "Apache Status" >> $TMPFILE
	echo "" >> $TMPFILE
	/usr/bin/lynx -dump -width 500 -connect_timeout=10 http://127.0.0.1/whm-server-status | grep -v ___ | grep -v OPTIONS >> $TMPFILE 2>&1
	echo "" >> $TMPFILE
	echo "" >> $TMPFILE
	echo "Busiest Sites" >> $TMPFILE
	echo "" >> $TMPFILE
	/usr/bin/lynx -dump -width 500 -connect_timeout=5 http://127.0.0.1/whm-server-status | awk  'BEGIN { FS = " " } ; { print $12 }' | sed '/^$/d' | sort | uniq -c | sort -rn >> $TMPFILE 2>&1
	echo "" >> $TMPFILE
	echo "" >> $TMPFILE
	echo "Netstat for Port 80 Abuse" >> $TMPFILE
	echo "" >> $TMPFILE
	netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -f1 -d: | sort | uniq -c | sort -rn | head >> $TMPFILE 2>&1
	echo "" >> $TMPFILE
	echo "" >> $TMPFILE
	echo "MySQL Process List" >> $TMPFILE
	echo "" >> $TMPFILE
	mysqladmin proc stat --verbose >> $TMPFILE 2>&1
	echo "" >> $TMPFILE
	echo "Process List" >> $TMPFILE
	echo "" >> $TMPFILE
	/bin/ps faux >> $TMPFILE 2>&1
	echo "" >> $TMPFILE
	echo "" >> $TMPFILE
	echo "Processes sorted by RESIDENT memory" >> $TMPFILE
	echo "" >> $TMPFILE
	ps -e -o pid,rss,vsz,args --sort -rss,-vsz >> $TMPFILE 2>&1



    #Send the email to the $contact address
	subject="[LW] Swapwatch.sh on $(hostname)"
	contents=$(cat $TMPFILE)

	/usr/sbin/sendmail "$contact" <<EOF
subject:$subject
$contents
EOF

    #restart apache to attempt to save server
    /etc/init.d/httpd restart > /dev/null 2>&1

    #log that swapwatch triggered
    echo "[ $(date +%c) ] swapwatch triggered - Load $load - Free swap $swap_free" >> /usr/local/lp/logs/swapwatch.log
  fi
#remove the tempfile
rm -f $TMPFILE
fi
