#!/bin/bash

printf "\033c" # Clear screen

# Get OS type
case "$OSTYPE" in
  cygwin*)
    OS=Windows
  ;;
  linux*)
    OS=Linux
  ;;
  darwin*)
    OS=OSX
  ;;
  *)
    echo "Unable to identify OS type $OSTYPE..."
    echo "Press ENTER key to continue..."
    read
    exit
  ;;
esac

# Get path variables
if [ "$OS" != "Windows" ]; then
  ROOTPATH=`pwd`
  AWK=awk
else
  ROOTPATH=`cygpath -m "$1"`
  AWK=gawk
fi
cd $ROOTPATH

FASTBOOT=$ROOTPATH/../tools/fastboot.exe

### Support function

function getkeys {
  read keyinput
  echo $keyinput
}

function clearkeys {
  while read -r -t 0; do read -r; done
}

function pause {
  if [ "$1" != "" ]; then
    echo $1
  fi
  clearkeys
  echo "Press ENTER key to continue..."
  read
}


function check_fastboot {
  if [ "`$FASTBOOT devices 2>&1 | grep fastboot`" != "" ]; then
    clearkeys
    echo 1
  else
    echo 0
  fi
}

function wait_fastboot {
  while [ $(check_fastboot) -eq 0 ]
  do
    sleep 1
  done
}

#######################################################

### Check rootpath
if [ "`echo $ROOTPATH | grep ' '`" != "" ]; then
  pause "This script does not support directory with space."
  exit
fi

if [ ${#ROOTPATH} -gt 200 ]; then
  pause "Path is too long, please extract script package in shorter path."
  exit
fi

echo 

echo 
pause "Shutdown phone use vol- and usb cable to enter fastboot"
echo

echo "Wait FASTBOOT connection...."
wait_fastboot
echo

echo -n "Give bootloader unlock code to relock fastboot: "
UNLOCK_CODE=$(getkeys)
echo "Use Vol-Up to select YES and press power button"
$FASTBOOT oem relock $UNLOCK_CODE
echo

