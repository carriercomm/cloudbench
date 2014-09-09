#!/bin/bash
#######################################################
# Copyright (C) 2011 
# Program: ioping.sh
# Shell script wrapper for ioping code.google.com/p/ioping/
# disk I/O latency measuring tool 
# Updated: September 1st, 2011 AEST 
DESC='shell wrapper script'
AUTHOR='by George Liu (eva2000)'
NAME='ioping'
SCRIPT="$NAME.sh"
SCRIPTURL='code.google.com/p/ioping/'
VER='0.9.8'
URL='http://vbtechsupport.com'
#######################################################

IOPINGVER='0.6'
REQUESTSIZE='4 32 64 256'

# Set paths
MAKE="$(which make)"

#######################################################

if [ -f /proc/mdstat ]; then
SOFTRAIDCHECK=`cat /proc/mdstat | grep active`

	if [[ ! -z $SOFTRAIDCHECK ]]; then
	DEVICES=`ls /sys/block/ | grep -E '(^sd|^md)'`
	else
	DEVICES='sd*'
	fi

else

DEVICES='sd*'

fi

#######################################################
# text functions

function funct_ddtest_title {

echo "**********************************"
echo "dd (sequential disk speed test)..."
echo "**********************************"

}

function funct_teststartinfo {

echo ""
echo "***************************************************"
echo "$NAME $SCRIPTURL"
echo "$SCRIPT $VER"
echo "$DESC $AUTHOR"
echo "$URL"
echo "***************************************************"

}

function funct_startingioping {

echo ""
echo "************************"
echo "starting ioping tests..."
#echo "************************"

}

function funct_iopingdiskiodefault {

echo "***************************************************"
echo "ioping disk I/O test (default 1MB working set)"
echo "***************************************************"

}

function funct_iopingdiskseekdefault {

echo "**********************************************"
echo "seek rate test (default 1MB working set)"
echo "**********************************************"

}

function funct_iopingdisksequentialdefault {

echo "**********************************************"
echo "sequential test (default 1MB working set)"
echo "**********************************************"

}

function funct_iopingcustomdiskio {

echo ""
echo "################################"
echo "ioping disk I/O test"
echo "(custom $REQUESTSIZE (KB) request size)"
echo "################################"

}

function funct_iopingcustomdiskseek {

echo "################################"
echo "ioping seek rate test"
echo "(custom $REQUESTSIZE (KB) request size)"
echo "################################"

}

#######################################################


function funct_ddtest {

	if [ -f /etc/rc.d/init.d/vzquota -o -f /proc/user_beancounters ]; then

	cd /home

	echo ""
	echo "Virtuzzo or OpenVZ Virtualisation detected"	

funct_ddtest_title

	echo "dd if=/dev/zero of=testfilex bs=64k count=16k conv=fdatasync"

	sleep 4

	dd if=/dev/zero of=testfilex bs=64k count=16k conv=fdatasync; rm -rf testfilex

	else

	echo ""
	cd /home

funct_ddtest_title

	echo "dd if=/dev/zero of=testfilex bs=64k count=16k conv=fdatasync"

	echo 3 > /proc/sys/vm/drop_caches
	sleep 4

	dd if=/dev/zero of=testfilex bs=64k count=16k conv=fdatasync; rm -rf testfilex

	fi

}

function funct_install {

cd /usr/local/src

echo ""
echo "***************************************************"
echo "Download ioping-${IOPINGVER}.tar.gz"
echo "***************************************************"

if [ -s ioping-${IOPINGVER}.tar.gz ]; then
  echo "ioping-${IOPINGVER}.tar.gz [found]"
  else
  echo "Error: ioping-${IOPINGVER}.tar.gz not found!!!download now......"
  wget -c http://ioping.googlecode.com/files/ioping-${IOPINGVER}.tar.gz
fi

echo ""
echo "***************************************************"
echo "Installing ioping ${IOPINGVER}"
echo "***************************************************"

tar xvzf ioping-${IOPINGVER}.tar.gz
cd ioping-${IOPINGVER}
make clean
make
make install

echo ""
echo "***************************************************"
echo "ioping ${IOPINGVER} installation complete"
echo "***************************************************"

}

function funct_scheduler {

echo "***************************************************"
echo "Disk Schedulers & Read Ahead (Queue Size x 2):"
echo "***************************************************"

for DEV in /sys/block/${DEVICES}
do

DEV=`echo ${DEV} | sed -e 's/\/sys\/block\///g'`

RA=`blockdev --getra /dev/${DEV} 2>/dev/null`

echo "[/dev/${DEV}] - Read Ahead: $RA"
cat /sys/block/${DEV}/queue/scheduler 2>/dev/null

echo "----------------------------------"

done

echo "***************************************************"

}

function funct_test {

funct_teststartinfo

funct_scheduler

funct_ddtest

echo 3 > /proc/sys/vm/drop_caches
funct_startingioping
sleep 5

funct_iopingdiskiodefault

for DEV in /sys/block/${DEVICES}
do

DEV=`echo ${DEV} | sed -e 's/\/sys\/block\///g'`

echo 3 > /proc/sys/vm/drop_caches
sleep 4

echo "disk I/O: /dev/${DEV}"
ioping -c 5 /dev/${DEV} | grep -E '(statistics|iops|mdev)'

echo ""
done

funct_iopingdiskseekdefault

for DEV in /sys/block/${DEVICES}
do

DEV=`echo ${DEV} | sed -e 's/\/sys\/block\///g'`

echo 3 > /proc/sys/vm/drop_caches
sleep 4

echo "seek rate: /dev/${DEV}"
ioping -R /dev/${DEV} | grep -E '(statistics|iops|mdev)'

echo ""
done

funct_iopingdisksequentialdefault

for DEV in /sys/block/${DEVICES}
do

DEV=`echo ${DEV} | sed -e 's/\/sys\/block\///g'`

echo 3 > /proc/sys/vm/drop_caches
sleep 4

echo "-----------------------"
echo "sequential: /dev/${DEV}"
ioping -RL /dev/${DEV} | grep -E '(statistics|iops|mdev)'
echo "-----------------------"
echo "sequential cached I/O: /dev/${DEV}"
ioping -RLC /dev/${DEV} | grep -E '(statistics|iops|mdev)'

echo ""
done

}

function funct_customtests {

echo ""
read -p "Run custom request size ${REQUESTSIZE} (KB) test ? [y/n]: " -t30 customtest;

if [ "$?" != "0" ]; then
	echo ""
	echo "You did not answer within 30 seconds. Exiting script..."
	exit 0
fi

########################################################
# custom tests begin

if [[ "$customtest" = [yY] ]]; then

funct_iopingcustomdiskio

for DEV in /sys/block/${DEVICES}
do

DEV=`echo ${DEV} | sed -e 's/\/sys\/block\///g'`

for WSIZE in $REQUESTSIZE

do

echo 3 > /proc/sys/vm/drop_caches
sleep 4

echo ""
echo "***************************************"
echo "[/dev/${DEV}] ioping disk I/O test: ${WSIZE}K test"
echo "***************************************"

ioping -c 5 -s ${WSIZE}K /dev/${DEV} | grep -E '(statistics|iops|mdev)'

done

echo ""
done

funct_iopingcustomdiskseek

for DEV in /sys/block/${DEVICES}
do

DEV=`echo ${DEV} | sed -e 's/\/sys\/block\///g'`

for WSIZE in $REQUESTSIZE

do

echo 3 > /proc/sys/vm/drop_caches
sleep 4

echo ""
echo "***************************************"
echo "[/dev/${DEV}] ioping seek rate test: ${WSIZE}K test"
echo "***************************************"

ioping -R -s ${WSIZE}K /dev/${DEV} | grep -E '(statistics|iops|mdev)'

done

echo ""
done

else

exit

fi

# custom tests end
########################################################

}

function funct_vztest {

funct_teststartinfo

funct_ddtest

#echo 3 > /proc/sys/vm/drop_caches
funct_startingioping
sleep 5

funct_iopingdiskiodefault

#echo 3 > /proc/sys/vm/drop_caches
#sleep 4

echo "disk I/O: /"
ioping -c 5 / | grep -E '(statistics|iops|mdev)'

echo ""

funct_iopingdiskseekdefault

#echo 3 > /proc/sys/vm/drop_caches
#sleep 4

echo "seek rate: /"
ioping -R / | grep -E '(statistics|iops|mdev)'

echo ""

funct_iopingdisksequentialdefault

#echo 3 > /proc/sys/vm/drop_caches
#sleep 4

echo "-----------------------"
echo "sequential: /"
ioping -RL / | grep -E '(statistics|iops|mdev)'
echo "-----------------------"
echo "sequential cached I/O: /"
ioping -RLC / | grep -E '(statistics|iops|mdev)'

echo ""

}

function funct_vzcustomtests {

read -p "Run custom request size ${REQUESTSIZE} (KB) test ? [y/n]: " -t30 customtest;

if [ "$?" != "0" ]; then
	echo ""
	echo "You did not answer within 30 seconds. Exiting script..."
	exit 0
fi

########################################################
# custom tests begin

if [[ "$customtest" = [yY] ]]; then

funct_iopingcustomdiskio

for WSIZE in $REQUESTSIZE

do

#echo 3 > /proc/sys/vm/drop_caches
#sleep 4

echo ""
echo "***************************************"
echo "[/] ioping disk I/O test: ${WSIZE}K test"
echo "***************************************"

ioping -c 5 -s ${WSIZE}K / | grep -E '(statistics|iops|mdev)'

done

echo ""

funct_iopingcustomdiskseek

for WSIZE in $REQUESTSIZE

do

#echo 3 > /proc/sys/vm/drop_caches
#sleep 4

echo ""
echo "***************************************"
echo "[/] ioping seek rate test: ${WSIZE}K test"
echo "***************************************"

ioping -R -s ${WSIZE}K / | grep -E '(statistics|iops|mdev)'

done

echo ""

else

exit

fi

# custom tests end
########################################################

}

########################################################

while :
do
	# clear
        # display menu
	echo "-----------------------------------------"
		echo "$SCRIPT $VER - $URL"
		echo "$AUTHOR"
	echo "-----------------------------------------"
	echo "          $SCRIPT $VER MENU"
	echo "-----------------------------------------"
	echo "1. Install ioping"
	echo "2. Re-install ioping"
	echo "3. Run ioping default tests"
	echo "4. Run ioping custom tests"
	echo "5. Exit"
	echo "-----------------------------------------"

	read -p "Enter option [ 1 - 5 ] " option
	echo "-----------------------------------------"

case "$option" in
1)

funct_install

;;
2)

funct_install

;;
3) 

if [ -f /usr/local/bin/ioping ]; then

	if [ -f /etc/rc.d/init.d/vzquota -o -f /proc/user_beancounters ]; then

	echo "Virtuzzo OR OpenVZ Virtualisation detected"	

	funct_vztest

	else

	funct_test

	fi

else

	echo "ioping not installed. To manually install, run ./ioping.sh install"
	echo ""

	read -p "Want to install ioping ? [y/n]: " -t30 askinstall;

	if [ "$?" != "0" ]; then
		echo ""
		echo "You did not answer within 30 seconds. Exiting script..."
		exit 0
	fi

	if [[ "$askinstall" = [yY] ]]; then

	funct_install

	else

	exit 0

	fi

fi

;;
4)

if [ -f /usr/local/bin/ioping ]; then

	if [ -f /etc/rc.d/init.d/vzquota -o -f /proc/user_beancounters ]; then

	echo "Virtuzzo OR OpenVZ Virtualisation detected"	

	funct_vzcustomtests

	else

	funct_customtests

	fi

else

	echo "ioping not installed. To manually install, run ./ioping.sh install"
	echo ""

	read -p "Want to install ioping ? [y/n]: " -t30 askinstall;

	if [ "$?" != "0" ]; then
		echo ""
		echo "You did not answer within 30 seconds. Exiting script..."
		exit 0
	fi

	if [[ "$askinstall" = [yY] ]]; then

	funct_install

	else

	exit 0

	fi

fi

;;
5)

echo ""
echo "exit"
exit 0

;;
*)

echo "$0 1 - install"
echo "$0 2 - reinstall"
echo "$0 3 - default tests"
echo "$0 4 - custom tests"

;;
esac

done

exit