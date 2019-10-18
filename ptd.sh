#!/bin/bash

######################################################  
#  Author : Prasad Gujar                             #
#  Script for taking multiple periodic thread dumps  #
######################################################

# Defining some color variables
r='\033[0;31m'
g='\033[0;32m'
n='\033[0m'

#echo $5
#echo $0

function jumpto
        {
         label=$1
          cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
          eval "$cmd"
          exit
         }

cwTD=`pwd`
case "$1" in 
	-F|-l)
         mde=$1
         shift


	if [[ "$mde" == -F && $EUID -ne 0 ]]; then
   		echo "This script must be run as root, if using option -F" 
   		exit 1
        fi
	# Some interactivity and validation
	shift
	getJAVAPATH: 2> /dev/null
	echo -n "Type JAVA_HOME, followed by [ENTER]:"
	read JAVA_HOME
	test -d $JAVA_HOME
	tjp=$?
	sleep 1
	cd $JAVA_HOME/bin >/dev/null 2>&1
	ls -lhtr | grep jstack >/dev/null 2>&1
	jst=$?
	sleep 1
	if [ -z "$JAVA_HOME" ] ; then
	   echo -e "${r}JAVA_HOME is empty${n}"
	   cd $cwTD 
	   jumpto getJAVAPATH
	elif [[  "$tjp" != 0 ]] ; then
		echo -e "${r}Invalid JAVA path${n}" >&2;
                cd $cwTD
                jumpto getJAVAPATH
	elif [ "$jst" !=  0 ]; then
		echo -e "${r}JSTACK application was not found${n}" >&2; exit 1
	fi
	#sleep 1

	cd $cwTD
	shift

        getTDPATH: 2> /dev/null	
	echo -n  "Type Thread Dump path , followed by [ENTER]:"
	
	read TD_PATH
	test -d $TD_PATH
	tdp=$?
	
	sleep 1
	
	if [ -z "$TD_PATH" ] ; then
	   echo -e "Thread Dump path is empty, continuing to use the current path as thread dump path" >&2;
           cd $cwTD
	   TD_PATH="`( cd \"$TD_PATH\" && pwd )`";
           sleep 1
	fi
	if [[  "$tdp" != 0 ]] ; then
		echo -e "${r}Invalid Thread Dump path${n}" >&2;
		jumpto getTDPATH
	elif ! [ -w $TD_PATH ] ; then
                echo $TD_PATH
		echo -e "Your user does not have write permissions to Thread Dump path mentioned";
		jumpto getTDPATH
	fi
	
	sleep 1

	cd $cwTD
	shift
        
        getPID: 2> /dev/null
	echo -n "Type Process PID, followed by [ENTER]:"

	read TD_PID
	re='^[0-9]+$'
	if [ -z "$TD_PID" ] ; then
	   echo -e "PID is empty" >&2; 
           jumpto getPID
	elif ! [[ $TD_PID =~ $re ]] ; then
	   echo "error: Not a number" >&2;
           jumpto getPID
	fi
	ps -aef | grep $TD_PID | grep java | grep -v grep >/dev/null 2>&1
	pidd=$?
			
	if [ "$pidd" != 0 ]; then
		echo -e "${r}Invalid PID${n}"
               jumpto getPID 
	fi
    
	cd $cwTD
	shift

	getNTD: 2> /dev/null
	echo -n "Number of Thread dumps to be taken [ENTER]:"

	read NTD
	sleep 1
	if ! [[ $NTD =~ $re ]] ; then
	   echo "error: Not a number" >&2;
           jumpto getNTD
	fi

        cd $cwTD
        shift

        getT: 2> /dev/null
	echo -n "Time interval of the threadump in seconds [ENTER]:"

	read TI
	if ! [[ $TI =~ $re ]] ; then
	   echo "error: Not a number" >&2;
           jumpto getT
	fi

	# Initialising some variables
	x=1;
	a=1;

	# Actual Stuff


	while [ $x -le $NTD ]
	do
		if [ $x = 1 ]; then
			echo -e "********  NOW TAKING THREAD DUMPS *************"
			sleep 2
		else
			echo -e "********  ${g}Now waiting for $TI seconds before taking  thread dump $a ${n} *************"
			sleep $TI
		fi
	echo -e "thread_dump $a ${r}is being taken${n}"
	$JAVA_HOME/bin/jstack $mde $TD_PID > $TD_PATH/TD_$a.txt
	sleep 1
	echo -e "thread dump $a ${g} is now available ${n}"
	sleep 1
	$((a++)) >/dev/null 2>&1
	((x++))
	done
	;;
	*)
	echo -e "Please use either -l or -F option , -l is recomended option. Use option -F only when the process is hung, or -l does not produce thread dumps. For using -F , please switch to Root first "
	exit 1
	;;
esac
	
##### Some quick analysis ######
cd $TD_PATH
for i in $( eval echo {1..$NTD} )
do
        echo "########################################################"
        echo "Below is a quick analysis for threaddump $i "
        cat TD_$i.txt | grep java.lang.Thread.State | sort -n | uniq -c
        echo "########################################################"
done

#################################


#########Cleaning UP#########
cd $TD_PATH
echo -e "***** ${g} moving below $NTD file/s in a gz archive named td_$(date '+%d_%m_%Y_%H_%M')...gz ${n} ***** "
sleep 1
#tar -cvzf td_$(date '+%d_%m_%Y_%H_%M_%S').tar.gz TD*.txt
tar -cvzf td_$(date '+%d_%m_%Y_%H_%M_%S').gz TD*.txt
sleep 2
rm TD*.txt
#############################