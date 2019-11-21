##Script Name:   file_list_generator.sh $FS_NAME $THRESHOLD $SERVER_NAME $INC_NUMBER $USERNAME
#!/bin/sh

PATH=/sbin:/bin:/usr/bin:/usr/sbin:$PATH

FS_NAME=$1            ## Filesystem
THRESHOLD=$2          ## Threshold value   
SERVER_NAME=$3        ## Server name
INC_NUMBER=$4         ## Incident number 
USERNAME=$5           ## User name  
os_flavor=`uname`     ## Fecth the OS

if [[ ${os_flavor} = Linux ]]; then
whereis bc | awk '{print $2}' | grep 'bc$' >/dev/null 2>&1
if [[ $? -ne 0 ]]; then apt install bc -y >/dev/null 2>&1; fi
whereis bc | awk '{print $2}' | grep 'bc$' >/dev/null 2>&1
if [[ $? -ne 0 ]]; then echo "bc not installed with apt, please loginto the server and check"; exit 1; fi

fi

##Generating the big file list
sudo touch /tmp/big_file_list /tmp/big_file_list_main /tmp/big_file_list_1.html
sudo chmod 777 /tmp/big_file_list /tmp/big_file_list_main /tmp/big_file_list_1.html /tmp/fsextend_main.sh 2>/dev/null
chown $USERNAME:$USERNAME /tmp/big_file_list /tmp/big_file_list_main /tmp/big_file_list_1.html /tmp/fsextend_main.sh 2>/dev/null

echo "BIG FILE LIST and OWNER INFO of $FS_NAME in $SERVER_NAME with $INC_NUMBER" >/tmp/big_file_list
echo "SIZE(Mb) OWNER FILENAME" >>/tmp/big_file_list

sudo find $FS_NAME -xdev -type f -size +50000 -exec ls -lrt {} \; | sort -r -k 5 | awk '{print $5/1024/1024,$3,$NF}' >>/tmp/big_file_list
sed '1,2d' /tmp/big_file_list >/tmp/big_file_list_main

sudo cp -p /tmp/big_file_list_main /tmp/big_file_list_1.html

