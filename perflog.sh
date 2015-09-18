#!/bin/ksh
#0 0 * * * /usr/local/perf/perflog.sh 6 240 /perfdata 1>/dev/null 2>/dev/null
#
# this file collects performance data on a daily basis
#
BINPATH=/usr/local/perf

if [ $# -ne 3 ]
then
   echo "usage:  $0 interval-in-minutes minute-count directory"
   exit 1
fi
date

let INTERVAL=$1
let COUNT=$2
DIR=$3 

echo "Collecting performance data for $2 $1-minute intervals in $DIR"

d=`date +%d`;m=`date +%m`;y=`date +%y`
cd $DIR
mkdir $d$m$y
cd $d$m$y


# get perf data
let I=$INTERVAL*60
vmstat -w $I $COUNT | awk '{ print $0 " " $13+$14; system("")}'  2>&1 | $BINPATH/chrono >> vmstat.out &

mpstat -P ALL $I $COUNT | $BINPATH/chrono >> mpstat.out &
iostat -dx $I $COUNT | $BINPATH/chrono >> iostat.out &
nicstat $I $COUNT | $BINPATH/chrono >> nicstat.out &
free -m > free.sample

th=`date +%H`
tm=`date +%M`
ts=`date +%S`
let x=$th*60+$tm
let c=0
while [ $x -lt 1440 -a $c -lt $2 ] && [ ! \( $th -eq 0 -a $c -gt 100 \) ]
do
	time=`echo "scale=2; $x/60" | bc`

        echo `who | wc -l` | $BINPATH/chrono >> usercount.out
        free -wm | grep Mem: | $BINPATH/chrono >> free.out

	echo -e "`date` - Count: $x\n\n" >> ps.out
        ps -e -o "pid,ppid,user,c,time,pcpu,pmem,rss,vsz,nlwp,args" | head -1 >> ps.out
	ps -e -o "pid,ppid,user,c,time,pcpu,pmem,rss,vsz,nlwp,args" | sed '1d' | sort -k 6 -nr >> ps.out
	echo -e "\n\n========================================================================================================\n\n" >> ps.out

        sleep $I

	th=`date +%H`
	tm=`date +%M`
	let x=$th*60+$tm
        let c=$c+1
done &
