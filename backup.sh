#!/bin/bash

#******************* VARIABLE *****************

BACKUPS_FOLDER="/var/backups"

# Using MAILGUN for mailing systems (should be free for enough emails notification)
MAILGUN_NAME="Username"			 # name (of sender)
MAIL_ADDRESS="dest@example.com"	 	 # dest
MAILGUN_ADDRESS="you@yourdomain.com"	 # from
MAILGUN_KEY="APIKEY" 			 # API key for mailgun
MAILGUN_DOMAIN="mg.example.com" 	 # mx domain for mailgun mg.example.com

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
	echo "$0 backup : create backup of / (detailed exclude in the script below)"
	echo "$0 restore myBackup.tar.gz : Restore from myBackup.tar.gz (write to /)"
	echo "$0 install : Install the backup in cron"
	exit
fi

# Check command (backup or restore)
if [ $1 = "backup" ]; then
	cd $BACKUPS_FOLDER
	day=$(date +%d-%m-%Y)


	echo "Creating list for package installed"
	apt-mark showauto > $BACKUPS_FOLDER/pkgs_auto.lst
	apt-mark showmanual > $BACKUPS_FOLDER/pkgs_manual.lst

	echo "Creating backup for $day at `date +\"%T\"`"
	BACKUP_NAME=$BACKUPS_FOLDER/backup-$day.tar.gz
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
	output=$(ls -lha $BACKUP_NAME)
	#echo "$output" | mail -s "Backup done" $MAIL_ADDRESS

	curl -s --user "$MAILGUN_KEY" \
		"https://api.mailgun.net/v3/$MAILGUN_DOMAIN/messages" \
		-F from="$MAILGUN_NAME $MAILGUN_ADDRESS" \
		-F to="$MAIL_ADDRESS" \
		-F subject='Server backup done' \
		-F text="Backup done : $output"
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

if [ $1 = "install" ]; then
	crontab -l > crontab-install-backup
	curr=$(pwd);
	full_path=$curr/$(basename "$0")
	echo "Script location : $full_path"
	echo "Writing to crontab"
	# Every 3 day with "backup" arg
	echo "0 20 */3 * * $full_path backup 2>&1 > $BACKUPS_FOLDER/backup.log" >> crontab-install-backup
	crontab crontab-install-backup

	echo "cleaning tmp file"
	rm crontab-install-backup
fi
