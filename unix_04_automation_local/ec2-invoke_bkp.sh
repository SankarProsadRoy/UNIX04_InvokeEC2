#!/bin/bash

## This script will invoke an ec2 instance by supplied varibale from SNOW
PATH=/sbin:/bin:/usr/bin:/usr/sbin:$PATH

current_directory="$(dirname "$0")"
echo "$*" >/tmp/local
sudo  cat /tmp/local | tr , '\n' >/etc/ansible/group_vars/local
sudo touch /etc/ansible/tempfile_$$
sudo ansible-playbook $current_directory/myplaybook_bkp.yml -vvv >$current_directory/tempfile_$$ 2>&1

instance_id=`grep -i -A 1 'instance_ids' $current_directory/tempfile_$$ | grep -v 'null' |  grep -i -A 1 'instance_ids' | tail -1 | sed 's/[ ]//g'`
sudo chmod 777 /etc/ansible/group_vars/local
sudo echo "instance_ids: $instance_id" >>/etc/ansible/group_vars/local

if [ $? -eq 0 ]; then
server_public_ip=`grep -i '"public_ip":' $current_directory/tempfile_$$  | head -1 | awk -F: '{print $NF}' | sed 's/,//g' |  sed 's/"//g'| sed 's/^[ ]//g' | sed 's/[ ]$//g'`
sudo ssh -qo "StrictHostKeyChecking no" -o ConnectTimeout=20 -i /home/ec2-user/.ssh/new_experimental.pem ec2-user@$server_public_ip <<EOF>>$current_directory/output_${server_public_ip}.txt
echo "Successful, I am currently logged into newly created `uname -n` server, instance id: $instance_id"
EOF
sudo cat $current_directory/output_${server_public_ip}.txt
sudo rm -f /tmp/local
else
echo "Ansible playbook not executed">>$current_directory/output_${server_public_ip}.txt
fi


sudo cat $current_directory/output_${server_public_ip}.txt

## Creating a group of newly created server in [dev-redhat] group
sudo sed '/dev-redhat.*/a '${server_public_ip}'' -i /etc/ansible/hosts

echo "server_public_ip='$server_public_ip'" >$current_directory/information





