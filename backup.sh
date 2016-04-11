#!/bin/bash

#******************* VARIABLE *****************

BACKUPS_FOLDER="/var/backups"

#**********************************************

echo "Executing : $*"
command -v apt-mark >/dev/null 2>&1 || { echo >&2 "apt-mark not installed. Aborting."; exit 1; }

# Check root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
# Check arguments
if [ $# -lt 1 ]; then
	echo "Usage :"
	echo "$0 backup"
	echo "$0 restore myBackup.tar.gz"
	exit
fi

# Check command (backup or restore)
if [ $1 = "backup" ]; then
	cd $BACKUPS_FOLDER
	jour=$(date +%d-%m-%Y)


	echo "Creating list for package installed"
	apt-mark showauto > $BACKUPS_FOLDER/pkgs_auto.lst
	apt-mark showmanual > $BACKUPS_FOLDER/pkgs_manual.lst

	echo "Creating backup for $jour"
	BACKUP_NAME=$BACKUPS_FOLDER/backup-$jour.tar.gz
	tar -cvpzf $BACKUP_NAME \
	--exclude=/dev/* \
	--exclude=/home/*/.gvfs \
	--exclude=/home/*/.mozilla/firefox/*/Cache \
	--exclude=/home/*/.cache/chromium \
	--exclude=/home/*/.thumbnails \
	--exclude=/media/* \
	--exclude=/mnt/* \
	--exclude=/proc/* \
	--exclude=/sys/* \
	--exclude=/tmp/* \
	--exclude=/home/*/.local/share/Trash \
	--exclude=/etc/fstab \
	--exclude=/var/run/* \
	--exclude=/var/lock/* \
	--exclude=/lib/modules/*/volatile/.mounted \
	--exclude=/var/cache/apt/archives/* \
	--exclude=node_modules \
	--exclude=/var/backups/*.tar.gz \
	--one-file-system /
	
	echo "Backup done, available at : $BACKUP_NAME" 
fi

if [ $1 = "restore" ]; then
	if [ $# -lt 2 ]; then
	        echo "Usage :"
	        echo "$0 restore myBackup.tar.gz"
        	exit
	fi

	FROM=$2

	echo "Restoring backup from $2"
	read -p "Are you sure?[y/N] " -n 1 -r
	echo ""

	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "RESTORING STARTED"
		tar -xvpzf $FROM -C / --numeric-owner
	else
		echo "Aborting"
	fi

fi
