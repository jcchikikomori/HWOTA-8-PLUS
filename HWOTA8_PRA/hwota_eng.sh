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
    echo -e "\e[1;31mPress ENTER to continue...\e[0m"
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
OEMPATH=$ROOTPATH/oeminfo
RECPATH=$ROOTPATH/recovery
FASTBOOT=$TOOLPATH/fastboot
ADB=$TOOLPATH/adb
UNLOCK_CODE=


##########################################################################################

function check_fastboot {
  if [ "`$FASTBOOT devices 2>&1 | grep fastboot`" != "" ]; then
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

function check_lock {
  if [ "`$FASTBOOT oem lock-state info 2>&1 | grep USER | grep UNLOCKED`" != "" ]; then
   echo 0
  else
   echo 1
  fi
}

function check_adb {
  if [ "`$ADB devices 2>&1 | grep recovery`" != "" ]; then
    echo 1
  else
    echo 0
  fi
}

function wait_adb {
  $ADB kill-server > /dev/null 2>&1
  while [ $(check_adb) -eq 0 ]
  do
    $ADB kill-server > /dev/null 2>&1
    sleep 1
  done
}

function pause {
  if [ "$1" != "" ]; then
    echo $1
  fi
  echo -e "\e[1;32mPress ENTER to continue...\e[0m"
  read
}

function unlock_device {
  if [ $(check_lock) -eq 1 ]; then
    echo -e "\e[1;36mBefore the next step, you need to unlock the loader.\e[0m"
    if [ "$UNLOCK_CODE" = "" ]; then
      echo -en "\e[1;33mEnter unlock code:\e[0m"
      UNLOCK_CODE=$(getkeys)
    else
      echo "Use unlock code $UNLOCK_CODE"
    fi
    echo
    echo -e "\e[1;31mUse the volume buttons to select YES and press the power button\e[0m"
    $FASTBOOT oem unlock $UNLOCK_CODE
    if [ "$1" != "" ]; then
      echo
      pause "$1"
    fi
  fi
}

function getkeys {
  read keyinput
  echo $keyinput
}

function isnum {
  if [ $(echo "$1" | grep -c '^[0-9]\+$') = 1 ]; then
    echo 1
  else
    echo 0
  fi
}

function format_str {
  strlen=${#1}
  count=$3
  remain=$(( count - strlen ))
  echo -n "$1"
  printf '%*s' "$remain"
}

function list_config {
  echo
  echo -e "\e[1;36m****************************************\e[0m"
  echo -e "\e[1;31m* $(format_str 'Model:  '$MODEL 37)*\e[0m"
  echo -e "\e[1;32m* $(format_str 'Build:  '$BUILD 37)*\e[0m"
if [ "$UPDATE_TYPE" = "1" ]; then
  echo -e "\e[1;33m* Source: SDCard HWOTA directory       *\e[0m"
else
  echo -e "\e[1;35m* Source: Script update directory      *\e[0m"
fi
if [ "$UPDATE_TYPE" = "1" ]; then
  echo -e "\e[1;37m* Update: Same brand update            *\e[0m"
else
  echo -e "\e[1;37m* $(format_str 'Update: Rebrand to '`echo $REBRAND | $AWK -F "/" '{print $NF}' | $AWK -F "." '{print $1}'` 37)*\e[0m"
fi
  echo -e "\e[1;36m****************************************\e[0m"
  pause
}

##########################################################################################

echo 
echo -e "\e[1;36m***************************************************\e[0m"
echo -e "\e[1;36m*                                                 *\e[0m"
echo -e "\e[1;31m* Written by Vovan1982 with 4PDA                  *\e[0m"
echo -e "\e[1;36m*                                                 *\e[0m"
echo -e "\e[1;36m***************************************************\e[0m"
echo 

if [ "`echo $ROOTPATH | grep ' '`" != "" ]; then
  pause "This script does not support a directory with space."
  exit
fi

if [ ${#ROOTPATH} -gt 200 ]; then
  pause "The path is too long, extract the script package on a shorter path."
  exit
fi


pause "Hold down the volume button minus and connect the USB cable to boot into the fastboot mode."
wait_fastboot

# Get product, model, and build
PRODUCT=`$FASTBOOT oem get-product-model 2>&1 | grep bootloader | $AWK '{ print $2 }'`
MODEL=`echo $PRODUCT | $AWK -F "-" '{ print $1 }'`
BUILD=`$FASTBOOT oem get-build-number 2>&1 | grep bootloader | $AWK -F ":" '{ print $2 }' | $AWK -F "\r" '{ print $1 }'`

unlock_device "After the phone is ready, turn off the power and use the Volume keys minus + USB cable to boot into the fastboot mode."
wait_fastboot

TWRP_FILE=`cd $RECPATH/PRA; ls | grep -i twrp`
TWRP=$RECPATH/PRA/$TWRP_FILE
echo
echo -e "\e[1;33mReplacing the Recavery runoff in TWRP, wait...\e[0m"
$FASTBOOT flash recovery_ramdisk $TWRP
echo
pause "Hold down the volume keys plus and on to load into TWRP."
pause "Wait for the device to boot into TWRP."

wait_adb

while [ 1 ]
do
echo 
echo -e "\e[1;31m****************************************\e[0m"
echo -e "\e[1;33m*      Upgrade options :               *\e[0m"
echo -e "\e[1;32m* 1. From the SD card                  *\e[0m"
echo -e "\e[1;32m* 2. Using the script                  *\e[0m"
echo -e "\e[1;31m****************************************\e[0m"
echo -n "Select: "
UPDATE_SOURCE=$(getkeys)
if [ $(isnum $UPDATE_SOURCE) -eq 1 ] && [ "$UPDATE_SOURCE" -gt "0" ] && [ "$UPDATE_SOURCE" -lt "3" ]; then
  break
fi
echo -e "\e[1;31mWrong select...\e[0m"
done

  FRP_FILE=`cd $RECPATH/PRA; ls | grep -i frp`
  RECOVERY_FILE=PRA_RECOVERY8_NoCheck.img
  FRP=$RECPATH/PRA/$FRP_FILE
  RECOVERY=$RECPATH/PRA/$RECOVERY_FILE
  FRP_TMP=/tmp/$FRP_FILE
  RECOVERY_TMP=/tmp/$RECOVERY_FILE
  TWRP_TMP=/tmp/$TWRP_FILE
  UPDATE_FILE=update.zip
  UPDATE_DATA_FILE=update_data_public.zip
  UPDATE_HW_FILE=update_all_hw.zip

if [ "$UPDATE_SOURCE" -eq "1" ]; then # SDCard
  SOURCE_PATH=
  SOURCE_UPDATE=
  SOURCE_UPDATE_DATA=
  SOURCE_UPDATE_HW=
  TARGET_PATH=/sdcard/HWOTA
  TARGET_UPDATE=$TARGET_PATH/$UPDATE_FILE
  TARGET_UPDATE_DATA=$TARGET_PATH/$UPDATE_DATA_FILE
  TARGET_UPDATE_HW=$TARGET_PATH/$UPDATE_HW_FILE
else # internal
  SOURCE_PATH=$ROOTPATH/update
  SOURCE_UPDATE=$SOURCE_PATH/$UPDATE_FILE
  SOURCE_UPDATE_DATA=$SOURCE_PATH/$UPDATE_DATA_FILE
  SOURCE_UPDATE_HW=$SOURCE_PATH/$UPDATE_HW_FILE
  TARGET_PATH=/data/update/HWOTA
  TARGET_UPDATE=$TARGET_PATH/$UPDATE_FILE
  TARGET_UPDATE_DATA=$TARGET_PATH/$UPDATE_DATA_FILE
  TARGET_UPDATE_HW=$TARGET_PATH/$UPDATE_HW_FILE
fi


while [ 1 ]
do
  echo 
  echo -e "\e[1;31m****************************************\e[0m"
  echo -e "\e[1;33m*       What would you like to do?     *\e[0m"
  echo -e "\e[1;32m* 1. Change firmware                   *\e[0m"
  echo -e "\e[1;32m* 2. Change location                   *\e[0m"
  echo -e "\e[1;31m****************************************\e[0m"
  echo -n "Select: "
  UPDATE_TYPE=$(getkeys)
  if [ $(isnum $UPDATE_TYPE) -eq 1 ] && [ "$UPDATE_TYPE" -gt "0" ] && [ "$UPDATE_TYPE" -lt "3" ]; then
    break
  fi
  echo -e "\e[1;31mWrong select...\e[0m"
done

if [ "$UPDATE_TYPE" = "1" ]; then
  list_config
fi

if [ "$UPDATE_TYPE" = "2" ]; then
  idx=0
  flist=($(ls $OEMPATH/PRA/* | sort))
  fsize=${#flist[@]}
  while [ 1 ]
  do
    idx=1
    echo 
    echo "****************************************"
    echo "* File replacement oeminfo:            *"
    for oem in "${flist[@]}"
    do
      echo -e "* $(format_str $idx.' '`echo $oem | $AWK -F "/" '{print $NF}' | $AWK -F "." '{print $1}'` 37)*"
      idx=$(( idx + 1 ))
    done
    echo "****************************************"
    echo -n "Select: "
    rb=$(getkeys)
    if [ $(isnum $rb) -eq 1 ] && [ "$rb" -gt "0" ] && [ "$rb" -lt "$(( fsize + 1 ))" ]; then
      break
    fi
    echo "Make a choice..."
  done
  REBRAND=${flist[$(( rb - 1 ))]}
  list_config
  echo 
  echo -e "\e[1;31mReplacing the oeminfo file with the selected one, please wait ...\e[0m"
  $ADB push $REBRAND /tmp/oeminfo
  $ADB push $FRP $FRP_TMP
  $ADB push $RECOVERY $RECOVERY_TMP
  $ADB push $TWRP $TWRP_TMP
  $ADB shell "dd if=$FRP_TMP of=/dev/block/mmcblk0p4"
  $ADB shell "dd if=$RECOVERY_TMP of=/dev/block/mmcblk0p32 bs=1048576"
  $ADB shell "dd if=$TWRP_TMP of=/dev/block/mmcblk0p28 bs=1048576"  
  $ADB shell "dd if=/tmp/oeminfo of=/dev/block/platform/hi_mci.0/by-name/oeminfo"
  $ADB reboot bootloader
  wait_fastboot
  echo
  unlock_device "Wait for the device to boot into TWRP."
fi

echo
echo -e "\e[1;35mWait for the files to load. Neither of which you do not need to press!!!.\e[0m"
echo

wait_adb

if [ "$UPDATE_SOURCE" = "2" ]; then
  $ADB shell "rm -fr $TARGET_PATH > /dev/null 2>&1"
  $ADB shell "mkdir $TARGET_PATH > /dev/null 2>&1"
  echo -e "\e[1;32mCopying is in progress ....\e[0m"
  $ADB push $SOURCE_UPDATE $TARGET_UPDATE
  echo
  echo -e "\e[1;32mCopying is in progress ....\e[0m"
  $ADB push $SOURCE_UPDATE_DATA $TARGET_UPDATE_DATA
  echo
  echo -e "\e[1;32mCopying is in progress ....\e[0m"
  $ADB push $SOURCE_UPDATE_HW $TARGET_UPDATE_HW
fi

echo
echo -e "\e[1;32mCopying recovery files, please be patient and wait....\e[0m"
$ADB push $RECOVERY $RECOVERY_TMP
$ADB shell "dd if=$RECOVERY_TMP of=/dev/block/mmcblk0p32 bs=1048576"
$ADB shell "dd if=$RECOVERY_TMP of=/dev/block/mmcblk0p28 bs=1048576"
$ADB shell "echo --update_package=$TARGET_UPDATE > /cache/recovery/command"
$ADB shell "echo --update_package=$TARGET_UPDATE_DATA >> /cache/recovery/command"
$ADB shell "echo --update_package=$TARGET_UPDATE_HW >> /cache/recovery/command"
$ADB reboot recovery
$ADB kill-server

echo
pause "The system update should start automatically."

