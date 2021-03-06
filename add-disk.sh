#!/bin/bash

# Disk adder

DiskName="sdb1"

echo "Disk Adder"

# Setup
echo "Adds a disk to a mount location."
if [ $(whoami) = "root" ]; then # If Root
  echo
  echo "Available disks"
  lsblk
  read -p "Enter the name of the disk you would like to add ("$DiskName"): " DiskNameNew
  if [ $DiskNameNew ]; then
    DiskName=$DiskNameNew
  fi
  echo
  read -p "Enter mount location. Leave blank to mount at /mnt/"$DiskName": " MountLocation
  if [ ! $MountLocation ]; then
    MountLocation="/mnt/"$DiskName
  fi
  if [ -d $MountLocation ]; then
    echo
    echo "This mount location already exists."
    read -p "Would you like to merge the contents of this directory? (Y|n): " MergeDirectory
    if [ ! $MergeDirectory ]; then
      MergeDirectory="y"
    fi
  fi
  echo
  read -p "Would you like "$DiskName" to mount on boot? (Y|n): " MountOnBoot
  if [ ! $MountOnBoot ]; then
    MountOnBoot="y"
  fi
  echo
  echo "WARNING: This operation will format "$DiskName"."
  read -p "Enter the name of the disk to verify you wish to continue: " Continue

  if [ $Continue = $DiskName ]; then # If Continue

    # Mount Disk
    echo
    echo "> Starting operations"
    echo "> Formatting "$DiskName" as Ext4 filesystem"
    mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/$DiskName
    if [ ${MergeDirectory,} = "y" ]; then # Merge Directory
      TempLocation="/mnt/"$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
      mkdir $TempLocation
      echo "> Mounting to temporary location"
      mount -o discard,defaults /dev/$DiskName $TempLocation
      chmod a+w $TempLocation
      echo "> Merging with "$MountLocation
      cp -rp $MountLocation/* $TempLocation
      mv -f $MountLocation $MountLocation"-temp"
      echo "> Mounting to "$MountLocation
      mkdir $MountLocation
      mount -o discard,defaults /dev/$DiskName $MountLocation
      chown --reference=$MountLocation"-temp" $MountLocation
      chmod --reference=$MountLocation"-temp" $MountLocation
      echo "> Unmouting temporary location"
      umount -l $TempLocation
      rm -rf $TempLocation
      rm -rf $MountLocation"-temp"
    else
      if [ -d $MountLocation ]; then
        echo "> Removing "$MountLocation
        rm -rf $MountLocation
      fi
      echo "> Mounting to "$MountLocation
      mkdir $MountLocation
      mount -o discard,defaults /dev/$DiskName $MountLocation
      chmod a+w $MountLocation
    fi

    # Add disk to /etc/fstab for mouting on boot
    if [ ${MountOnBoot,} = "y" ]; then 
      echo "> Adding disk to /etc/fstab for mouting on boot."
      echo "/dev/"$DiskName" "$MountLocation" ext4 discard,defaults 1 1" | tee -a /etc/fstab
    fi

  else #Not Continue
  echo
  echo "The name of the disk did not match the name of the disk you wish to mount."

  fi #End Continue

else #Not Root
echo
echo "This command must be run as root."

fi #End Root
echo
echo "Exiting"
echo
