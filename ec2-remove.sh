#!/bin/bash

## This script will invoke an ec2 instance by supplied varibale from SNOW
PATH=/sbin:/bin:/usr/bin:/usr/sbin:$PATH

current_directory="$(dirname "$0")"
source /etc/ansible/information
sudo ansible-playbook $current_directory/ec2-terminate.yaml -vvv

sudo sed -i '/^'$server_public_ip'$/d' /etc/ansible/hosts





