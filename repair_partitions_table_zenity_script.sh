#! /bin/bash

##############################################################
#
# Simple script with Zenity GUI to backup, restore or repair partitions table.
# Tested on Ubuntu 14.04 (and probably will work with Debian).
# By Ahmed M. AbouZaid, July 2014, under MIT license.
# 
##############################################################

#Check if gksu, sfdisk and gdisk (fixparts) are installed.
if [[ ! -f /usr/bin/gksu ]]; then
    zenity --error --text="Please Install gksu!"
    /usr/bin/software-center gksu
elif [[ ! -f /sbin/sfdisk ]]; then
    zenity --error --text="Please Install sfdisk!"
    /usr/bin/software-center util-linux
elif [[ ! -f /sbin/fixparts ]]; then
    zenity --error --text="Please Install gdisk!"
    /usr/bin/software-center gdisk
fi

#Select hard disk if there are many.
harddisk=$(zenity --list \
 --title="Choose hard disk" \
 --column="Hard disk" --column="Size" \
    $(lsblk | grep disk | awk '{print "/dev/"$1,$4}')
)
  if [[ $? = 1 ]]; then
    exit
  fi

#Backup, restore or repair partitions table dialog.
partition_tables_dialog () {
partition_tables_action=$(zenity --list --radiolist \
 --title="What do you want to do?" \
 --column="   " --column="Action" \
    FALSE "Backup partitions table." \
    FALSE "Restore partitions table." \
    FALSE "Repair partitions table."
)
}

#Check exit status and return message in the case of success or fails.
check_exit_status () {
    if [[ $? = 0 ]]; then
      zenity --info --text="Done"
    else
      /usr/bin/printf '=%.0s' {1..50} >> /tmp/sfdisk.log
      zenity --error --text="Sorry! Unexpected error! Please check logs: /tmp/sfdisk.log"
    fi
}

while :
do
#Run partition tables dialog.
partition_tables_dialog

#Checking the user's choice. 
case "$partition_tables_action" in
#-------------------------------------------------------------
  "Backup partitions table.")
    #Dump the partitions of a device.
    /usr/bin/gksu /sbin/sfdisk -d $harddisk > ~/partitions_table_backup_$(date +%Y%m%d).dump 2>> /tmp/sfdisk.log

    #Check exit status of previous command and return to main dialog.
    if [[ $? = 0 ]]; then
      zenity --info --text="You can find partitions table backup file in your Home with name \"partitions_table_backup_$(date +%Y%m%d).dump\""
    else
      /usr/bin/printf '=%.0s' {1..50} >> /tmp/sfdisk.log
      zenity --error --text="Sorry! Unexpected error! Please check logs: /tmp/sfdisk.log"
    fi
  ;;
#-------------------------------------------------------------
  "Restore partitions table.")
    #Restore the partitions table.
    /usr/bin/gksu /sbin/sfdisk -f $harddisk < $(zenity --file-selection --title="Select a File") >> /tmp/sfdisk.log 2>&1

    #Check exit status of previous command and return to main dialog.
    check_exit_status
  ;;
#-------------------------------------------------------------
  "Repair partitions table.")
    #Run Fixparts in non-interactive mode to repair partitions table.
    /usr/bin/gksu /sbin/fixparts $harddisk << EOD
Y
w
yes
EOD

    #Check exit status of previous command and return to main dialog.
    check_exit_status
  ;;
#-------------------------------------------------------------
  *)
    if [[ $? = -1 ]]; then
      zenity --error --text="Sorry! Unexpected error!"
      break
    else
      break
    fi
  ;;
esac
done