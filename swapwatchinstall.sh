#!/bin/bash
#this will create swapwatch.sh, swapwatch.conf, and crontab to run swapwatch.sh, and swapwatchupdater

###############################################################################

APPDIR="/usr/local/lp/apps/swapwatch"
LOGDIR="/usr/local/lp/logs"
CONFDIR="/usr/local/lp/configs/swapwatch"
swapurl="http://layer3.liquidweb.com/monitoring/swapwatch.sh" #this will be appserv or nagilink
updateurl="http://layer3.liquidweb.com/monitoring/swapupdate.sh" #this will be appserv or nagilink

###############################################################################

#set default values, these can be changed in swapwatch.conf, but they are
#better than ridgid default values

#cpus is an easy count
cpus=$(grep processor /proc/cpuinfo -c)
#memory in kB
memory=$(grep MemTotal /proc/meminfo |awk '{print $2}')

#load trigger is 5 * CPUs
loadthresh=$( expr $cpus \* 5 )

#memory is: 2G thresh for 7+, 1G for 2+, .5G for less than that
G=1048576 #your a gigabyte
if [ $memory -gt $( expr 7 \* $G ) ]
then   
        swapthresh=$( expr 2 \* $G )
elif [ $memory -gt $( expr 2 \* $G ) ]
then   
        swapthresh=$G
else   
        swapthresh=$( expr $G / 2 )
fi

###############################################################################

##create the config file
#loadthreshold=5
#swapthreshold=1048576
#update=yes
mkdir -p "$CONFDIR"
cat > "$CONFDIR/swapwatch.conf" << EOM
loadthreshold=$loadthresh
swapthreshold=$swapthresh
update=yes
contact="support@liquidweb.com"
EOM

###############################################################################

#install
mkdir -p "$APPDIR"
echo "downloading swapwatch.sh"
wget -O "$APPDIR/swapwatch.sh" $swapurl
chmod +x "$APPDIR/swapwatch.sh"
echo "*/3 * * * * root $APPDIR/swapwatch.sh > /dev/null 2>&1" > /etc/cron.d/swapwatch

###############################################################################

##get update script
wget -O "$APPDIR/swapupdate.sh" $updateurl
chmod +x "$APPDIR/swapupdate.sh"
##check randomly once a week, to prevent tons of simmul conns to appserv
min=$[ ( $RANDOM % 60 ) ] #0-59
hour=$[ ( $RANDOM % 24 ) ] #0-23
dow=$[ ( $RANDOM % 7 ) ] #0-6
# $min $hour * * $dow
echo "$min $hour * * $dow root $APPDIR/swapupdate.sh > /dev/null 2>&1" > /etc/cron.d/swapupdate

###############################################################################

#log install
echo "[ $(date +%c) ] Swapwatch installed" >> $LOGDIR/swapwatch.log
