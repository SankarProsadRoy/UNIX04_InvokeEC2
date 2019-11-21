#!/bin/bash

PATH=/sbin:/bin:/usr/bin:/usr/sbin:$PATH
export PS1="# "

#if [ $1 = data ]; then
#umount /mnt
#if [ $? -eq 0 ]; then
#pvcreate /dev/sdb1
#vgcreate vg01 /dev/sdb1
#lvcreate -n data_lv -L +1G vg01
#mkfs.ext4 /dev/vg01/data_lv
#mkdir -p /data
#fi

#mount /dev/vg01/data_lv /data 2>/dev/null

if [[ $1 = oradata ]]; then
umount /oradata
lvchange -an /dev/ora_vg/ora_lv
lvremove /dev/ora_vg/ora_lv -y
vgremove /dev/ora_vg
if [ $? -eq 0 ]; then
pvcreate /dev/xvdb1
vgcreate ora_vg /dev/xvdb1
lvcreate -n ora_lv -L +4G ora_vg -y
mkfs.ext4 /dev/ora_vg/ora_lv
mkdir -p /oradata
fi
mount /dev/ora_vg/ora_lv /oradata 2>/dev/null
if [ $? -eq 0 ]; then
sudo cp -p /demodata/testfile_*.log* /oradata/ 
sudo cp -p /demodata/testfile_104 /oradata/1stfile &
sudo cp -p /demodata/testfile_104 /oradata/2ndfile &
sudo cp -p /demodata/testfile_104 /oradata/3rdfile &
sudo cp -p /demodata/testfile_104 /oradata/4thfile &
sudo cp -p /demodata/testfile_104 /oradata/5thfile &
sudo cp -p /demodata/testfile_104 /oradata/6thfile &
sudo cp -p /demodata/testfile_104 /oradata/7thfile &
sudo cp -p /demodata/testfile_104 /oradata/8thfile &
sudo cp -p /demodata/testfile_104 /oradata/9thfile &
sudo cp -p /demodata/testfile_104 /oradata/10thfile &
sudo cp -p /demodata/testfile_104 /oradata/11thfile &
sudo cp -p /demodata/testfile_104 /oradata/12thfile &
sudo cp -p /demodata/testfile_104 /oradata/13thfile &
sudo cp -p /demodata/testfile_104 /oradata/14thfile &
sudo cp -p /demodata/testfile_104 /oradata/15thfile &
sudo cp -p /demodata/testfile_104 /oradata/16thfile &
sudo cp -p /demodata/testfile_104 /oradata/17thfile &
sudo cp -p /demodata/testfile_104 /oradata/18thfile &
sudo cp -p /demodata/testfile_104 /oradata/19thfile &
sudo cp -p /demodata/testfile_104 /oradata/20thfile &
fi
fi
