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


sudo grep 'PasswordAuthentication no'  /etc/ssh/sshd_config
if [ $? -eq 0 ]; then
for line in `sudo cat /etc/ssh/sshd_config | awk '{print NR,$0}' | grep 'PasswordAuthentication no'  | awk '{print $1}'`
  do
    sudo sed ''$line\s'/^/#/' -i /etc/ssh/sshd_config  ## Commenting no password authentication
  done
for line in `sudo cat /etc/ssh/sshd_config | awk '{print NR,$0}' | grep '#PasswordAuthentication yes'  | awk '{print $1}'`
  do
    sudo sed ''$line\s'/^#//' -i /etc/ssh/sshd_config  ## enabling password authentication
  done
 else
     sudo echo "PasswordAuthentication yes" >>/etc/ssh/sshd_config
 fi

sudo grep 'PasswordAuthentication yes'  /etc/ssh/sshd_config
if [ $? -ne 0 ]; then
   sudo echo "PasswordAuthentication yes" >>/etc/ssh/sshd_config
fi

echo -e "$2\n$2" | passwd $1   ## Changing password for user

sshd_restart_serial

