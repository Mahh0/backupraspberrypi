## About the project
Bash script which create a compressed save of some folders and sent them to a remote computer using ssh/scp.
This small bash script will run everyday at 7am thanks to a systemd service and a systemdtimer

How it works :
1 - Pause docker containers than can cause trouble reading some files
2 - Create an archive of the files 
3 - Unpause containers
4 - Check if computers waked up and if not, WOL it
5 - SCP Transfer and removal of local backup
6 - Turn off the computer if it was waked on lan previously


What does it needs

1. .ssh folder :
It needs a config file into the .ssh folder of the user who will run the program. Example of the config file : 
```
HOST       desktopmaho
USER       thisismyser (can be an email address)
HOSTNAME   192.168.1.108
PORT       22
```

It also needs a file containing your windows password

2. Systemd
backup.service (no systemctl enable)
```
[Unit]
Description=Script de backup
After=network-online.target

[Service]
Type=simple
ExecStart=/root/backup.sh
WorkingDirectory=/root/
User=root

[Install]
WantedBy=default.target
```

backup.timer (need a systemctl enable)
```
[Unit]
Description=Backup auto tous les jours à 7h00

[Timer]
OnCalendar=*-*-* 7:30:00
Persistent=true
Unit=backup.service

[Install]
WantedBy=timers.target
```

3. Personalize the script
=> backup_files variable
=> dest variable
=> docker : comment/uncomment
=> ip addresses of remote host
=> remote folder in scp command



