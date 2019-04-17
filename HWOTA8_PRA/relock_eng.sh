

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
    echo -e "\e[1;32mUnable to identify OS type $OSTYPE...\e[0m"
    echo -e "\e[1;33mPress ENTER to continue...\e[0m"
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

TOOLPATH=$ROOTPATH/tools/$OS
FASTBOOT=$TOOLPATH/fastboot
UNLOCK_CODE=

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
  echo -e "\e[1;36mPress ENTER to continue...\e[0m"
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
  pause "This script does not support a directory with space."
  exit
fi

if [ ${#ROOTPATH} -gt 200 ]; then
  pause "The path is too long, extract the script package on a shorter path."
  exit
fi

echo 

echo 
pause "Hold down the volume button minus and connect the USB cable to boot into the fastboot mode."
echo

echo "Waiting connection in FASTBOOT..."
wait_fastboot
echo

echo -en "\e[1;32mEnter unlock code: \e[0m"
UNLOCK_CODE=$(getkeys)
echo -e "\e[1;31mUse the volume buttons to select YES and press the power button\e[0m"
$FASTBOOT oem relock $UNLOCK_CODE
echo
pause 