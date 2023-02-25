#!/bin/bash

######################################################  
#  Author : Prasad Gujar                             #
#  Script for taking multiple periodic thread dumps  #
#  version : 3.0                                     #
######################################################

# Defining some color variables
r='\033[0;31m'
g='\033[0;32m'
n='\033[0m'

cwTD=`pwd`

function javaVars {
	test -d $JAVA_HOME
        tjp=$?
        cd $JAVA_HOME/bin >/dev/null 2>&1
        ls -lhtr | grep -w jstack >/dev/null 2>&1
        jst=$?
      }


function javaPATH {
   	echo -n "Type JAVA_HOME, followed by [ENTER]:"
	read JAVA_HOME
	test -d $JAVA_HOME
	tjp=$?
	cd $JAVA_HOME/bin >/dev/null 2>&1
	ls -lhtr | grep -w jstack >/dev/null 2>&1
	jst=$?
	}

function javaEmptyCheck {
        while [ -z "$JAVA_HOME" ] ; do
                echo -e "${r}JAVA_HOME is empty, please enter proper JAVA_HOME path ${n}"
                cd $cwTD
                javaPATH
        done
        }

function invalidJavaCheck {
        while [  "$tjp" != 0 ] ; do
                echo -e "${r}Java_HOME path is invalid , please enter proper JAVA_HOME${n}"
                cd $cwTD
                javaPATH
                javaEmptyCheck
        done
        }

function jstackCheck {
	if [ "$jst" !=  0 ]; then
        	echo -e "${r}JSTACK application was not found${n}" >&2; exit 1
	fi

        }

function javaCheck {
        
             javaVars
             invalidJavaCheck
             jstackCheck
           }

function tdPATH {
        echo -n "Type Thread Dump path , followed by [ENTER]:"
        read TD_PATH
        test -d $TD_PATH
        tdp=$?
        test -d $JAVA_HOME
        }

function emptdPATH {
            
	   if [ -z "$TD_PATH" ] ; then
	   echo -e "Thread Dump path is empty, continuing to use the current path as thread dump path" >&2;
           cd $cwTD
	   TD_PATH="`( cd \"$TD_PATH\" && pwd )`";
	fi
        }

function tdINVALIDPATH {
	while [[  "$tdp" != 0 ]]; 
	do echo -e "${r}Invalid Thread Dump path${n}"
	    tdPATH
            emptdPATH
	done
}

function tdpathPERM {	
        while ! [ -w $TD_PATH ] ; 
        do  echo -e "Your user does not have write permissions to Thread Dump path mentioned"
           tdPATH
           emptdPATH
        done
        }

function wlsPID {
        echo
	echo "############################## Below WLS Process IDs are Running on this server #############"
        echo
	ps -aef | grep -v grep  | grep Dweblogic.Name | awk '{ print $2 " " $16 }'
		
        echo
        echo "############################################################################################"
  	echo
        }

function checkPID {
        ps -aef | grep -v grep | grep  java | grep $TD_PID  > PID.txt
        pidd=$?
	} 

function getPID { 
	echo -n "Type Process PID, followed by [ENTER]:"
	read TD_PID
	re='^[0-9]+$'
	}
function checkValidPID {
	checkPID
        while [ "$pidd" != "0" ]
        do
        echo -e "INVALID PID"
        unset TD_PID
        getPID
        checkPID
        checkemptPID
        numCHECKPID
        done
        }


function checkemptPID {
		while [ -z "$TD_PID" ] ; do
                echo -e "PID is empty"
		getPID
		done
		}

function numCHECKPID {
                re='^[0-9]+$'
                while ! [[ $TD_PID =~ $re ]]
                do
                echo "error Not a number"
		getPID
		checkemptPID
                done
		}


function numTD { 
		echo -n "Number of Thread dumps to be taken [ENTER]:"
		read NTD
         }
function numCheck {
                re='^[0-9]+$'
		while  ! [[ $NTD =~ $re ]] 
		do
		  echo "error: Not a number"
           	  numTD
		done
                }

function timeTD {
		echo -n "Time interval of the threadump in seconds [ENTER]:"
		read TI
		}

function timeCheck {
		while  ! [[ $TI =~ $re ]]
		do
		 echo "error: Not a number"
                 timeTD
		done
		}

function takePTD {
    if ! [ -z "$JAVA_HOME" ] ; then 
    javaCheck
    else
    javaPATH
    javaEmptyCheck
    invalidJavaCheck
    jstackCheck
    fi

    tdPATH
    emptdPATH
    tdINVALIDPATH
    tdpathPERM

    #wlsPID

    getPID
    checkemptPID
    numCHECKPID
    checkValidPID

    numTD
    numCheck
    timeTD
    timeCheck

    # Initialising some variables
	x=1;
	a=1;

       ## Actual Stuff
	while [ $x -le $NTD ]
	do
		if [ $x = 1 ]; then
			echo -e "********  NOW TAKING THREAD DUMPS *************"
			sleep 1
		else
			echo -e "********  ${g}Now waiting for $TI seconds before taking  thread dump $a ${n} *************"
			sleep $TI
		fi
	echo -e "thread_dump $a ${r}is being taken${n}"
	$JAVA_HOME/bin/jstack $mde $TD_PID > $TD_PATH/TD_$a.txt
	sleep 1
	echo -e "thread dump $a ${g} is now available ${n}"
	sleep 1
	#$((a++)) >/dev/null 2>&1
	((a++))
	((x++))
	done

}

cwTD=`pwd`
case "$1" in 
	-F|-l)
    mde=$1
    shift
    takePTD
  	;;
	*)
    takePTD
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
rm PID.txt
#############################
