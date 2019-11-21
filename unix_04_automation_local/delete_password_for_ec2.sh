#!/bin/bash
## This script will enable password login for ec2-user
PATH=/sbin:/bin:/usr/bin:/usr/sbin:$PATH

sshd_restart_serial()     {

   sudo systemctl  status sshd >/dev/null
if [ $? -eq 0 ]; then
   sudo systemctl  restart sshd >/dev/null
else
    sudo systemctl start sshd >/dev/null
fi

}

for line in `sudo cat /etc/ssh/sshd_config | awk '{print NR,$0}' | grep 'PasswordAuthentication yes'  | awk '{print $1}'`
  do
    sudo sed ''$line\s'/^/#/' -i /etc/ssh/sshd_config   ## disabling password authentication
  done

for line in `sudo cat /etc/ssh/sshd_config | awk '{print NR,$0}' | grep '#PasswordAuthentication no'  | awk '{print $1}'`
  do
    sudo sed ''$line\s'/^#//' -i /etc/ssh/sshd_config    ## Enabling no password authentication
  done

sudo passwd -d $1      ## Deleting the password for user
sshd_restart_serial
