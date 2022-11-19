#!/bin/bash

###########################
#
# Backup files in given directories, directly entered in the script :
#	- Compress the folders content
#	- Send it through FTP/SMB to home computer
#
# Default backup folders :
#	- /home/
#	- /root/
#	- /srv/dev-disk-by-uuid-82af1025-3cca-434e-84b5-d766c9c6bf71/Keepass
#	- /srv/dev-disk-by-uuid-82af1025-3cca-434e-84b5-d766c9c6bf71/Private
#	- /srv/dev-disk-by-uuid-82af1025-3cca-434e-84b5-d766c9c6bf71/Public
#
#
###########################
# Hour for logs
hour = $(date '+%Y-%m-%d %H:%M')


#Creating archive filename
day=$(date '+%Y-%m-%d')
hostname=$(hostname -s)
archive_file="$hostname-$day.tgz"

# Hello message
echo -e "##################################\n##    Starting files backup     ##\n## Current date : $hour    ##\n##################################"
echo -e "\n"


#What to backup
backup_files="/home /root /srv/samba/Private /srv/samba/Keepass /srv/samba/Public /etc/systemd/system"


# Where to create the backup
dest="/srv/samba/backups/"


# Test if HDD accessible
if ! [[ -d "$dest" && -x "$dest" ]]; then
	echo "ERROR : HDD Not accessible !"
	echo -e "\n"
	exit 1
fi


# Print start status message.
echo "INFO - Backing up $backup_files to $dest/$archive_file"
echo -e "\n"


# Pause docker containers and systemd services
echo "INFO - Pausing docker containers..."
echo -e "\n"
docker pause $(docker ps -q)
echo "INFO - Dockers containers paused !"
echo -e "\n"


# Backup the files using tar.
# syntaxe : tar xzf chemin/nom_archive fichiers_a_compresser
# test si un fichier d'archive existe déjà au même nom
if [[ -f "$dest/$archive_file" ]]; then
    echo "WARNING - $archive_file already  exists ! deleting it..."
    echo -e "\n"
    rm $dest/$archive_file > /dev/null 2>&1 && echo "File successfuly deleted !" || ( echo "Can't delete this file ! aborting ..." && docker unpause $(docker ps --filter "status=paused") && sleep 5 && exit 1 )
fi
# compression des fichiers demandes, si pas reussi erreur
if tar czf $dest/$archive_file $backup_files
then
	echo "INFO - Compression success ! Now sending to desktop !"
	echo -e "\n"
else
	echo "ERROR - Error in the tar compression ! Unpausing docker containers and exiting !"
	echo -e "\n"
	docker unpause $(docker ps -q --filter "status=paused")
	exit 1
fi


# Resuming paused containers
echo "INFO - Unpausing docker containers !"
echo -e "\n"
docker unpause $(docker ps -q --filter "status=paused")
echo "INFO - Docker containers unpaused"
echo -e "\n"


# Send to desktop
	# First, test if the computer is on, if not, wake it up
PING=`ping -s 1 -c 2 "192.168.1.108" > /dev/null; echo $?`
if [ $PING -eq 0 ];then
        echo -e "Host is UP \n"
elif [ $PING -eq 1 ];then
        wakeonlan 88:d7:f6:c8:16:e4 | echo "Host not turned on. WOL packet sent"
        sleep 3m | echo "Waiting 3 Minutes"
        PING=`ping -s 1 -c 4 "192.168.1.108" > /dev/null; echo $?`
        if [ $PING -eq 0 ];then
                echo "Host is UP after wake on lan"
                echo -e "\n"
        else
                echo "Host still down"
                echo -e "\n"
		exit 1
        fi
fi



	# Computer is on : do the transfer
sshpass -f "/root/password" scp -C -r /srv/samba/backups/$archive_file desktopmaho:/E:/Saves

if [ $? -eq 0 ];
then
    echo "INFO - Transfer successful"
    echo -e "\n"
else
    echo "ERROR - Transfer failed !"
    echo -e "\n"
    exit 1
fi

# Deleting the backup file from the disk
rm -r /srv/samba/backups/$archive_file > /dev/null 2>&1 && echo "Backup successfuly deleted from disk" || ( echo "Error while deleting the backup from the disk !" && exit 1 )


# Ending
echo "Backup successful !"
