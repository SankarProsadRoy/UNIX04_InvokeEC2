#!/bin/bash

## Scriptname: unix04_main.sh
## Author    : Arindam Ghosh
## Date      : 31/12/2018


## Synopsis: This script is intended to automate the manual action taken from L1 and L2 Unix team, upon receiving a file-system threshold breaching alert
##           This is a bash script, where mutt has been outgoing email client, sshpass has been used to build the ssh tunnel between source server and 
##           remote servers. This script execution will be initiated from Universal Service Portal(USP) in Sanofi environment. Parameter like threshold, 
##           file-system name etc will be parsed here from Service now


PATH=/sbin:/bin:/usr/bin:/usr/sbin:$PATH


FS_NAME_1=$2
if [[ `echo $FS_NAME_1 | awk '{print substr($0,0,1)}'` !=  "/" ]]; then FS_NAME_="/$FS_NAME_1"; else FS_NAME_="$FS_NAME_1"; fi
if [[ $FS_NAME_1 = "root" ]] || [[ $FS_NAME_1 = "/root" ]]; then FS_NAME_="/"; fi
THRESHOLD_=$1
SERVER_NAME=`uname -n`
USERNAME=root
PASSWORD=dummy
INC_NUMBER=INC123456
##Omitting the floater part from threshold value
THRESHOLD=$(echo $THRESHOLD_ | awk -F. '{print $1}')

exit_function()    {

if [ $? -ne 0 ]
    then echo "$1" >>$log_file
         echo "$1"
         exit 1
fi

}


current_directory="$(dirname "$0")"
baseserver=`echo $SERVER_NAME|awk -F. '{print $1}'`                                           ## Execution server
mailsender=`whereis mutt|awk '{print $2}'`                                                    ## mail sender package
mkdir -p $current_directory/logs
log_dir=${current_directory}/logs                                                             ## Log directory
log_file=${log_dir}/`basename $0`.log                                                         ## Log file
ssh_command="echo TEST"

>$log_file

cd $current_directory
exit_function "Unable to change to script directory"



perm_change()       {

sudo mkdir -p /tmp/$SERVER_NAME
sudo chmod -R 777 /tmp/$SERVER_NAME/
sudo chown -R $USERNAME:$USERNAME /tmp/$SERVER_NAME/

}

echo "\nCurrent date and time is: `date '+%d%m%Y-%H:%M'`\nIncident number: $INC_NUMBER\nServer Name: $SERVER_NAME\nFSNAME: ${FS_NAME_}\nTHRESHOLD VALUE: $THRESHOLD\nCURRENT_FS_UTIL:" >>$log_file



credvalidation()    {
sshpass -p "$3" ssh -qo "StrictHostKeyChecking no" -o ConnectTimeout=20 "$1"@"$2" "${4}" >${current_directory}/.sshvalidation
}


## Copying .muttrc config file to user's home directory ##
sudo cp -p /root/.muttrc /home/${USERNAME}

exit_function "unable to copy the .muttrc file to user's home direcory"

unix_flavor=`uname`

## To overcome case sensetivity of UNIX FS_NAME
FS_NAME=`/bin/sh $current_directory/fs_name_puller.sh $FS_NAME_`

if [ -z $FS_NAME ]; then 
if [[ `echo $FS_NAME_ | awk -F_ '{print $NF}'` = "vxfs" ]] || [[ `echo $FS_NAME_ | awk -F_ '{print $NF}'` = "VXFS" ]]; then FS_NAME_=`echo $FS_NAME_ | awk -F_ '{print $1}'`; fi
FS_NAME=`/bin/sh $current_directory/fs_name_puller.sh $FS_NAME_`
if [ -z $FS_NAME ]; then 
echo "$FS_NAME_ does not exist" >>$log_file; exit 1; fi
fi

## Check if file system exists  ##
df -k "$FS_NAME" >>$log_file 2>&1
exit_function "$FS_NAME does not exist"

## ~~~ Big file list generator script execution in remote host ~~~ ##
/bin/sh $current_directory/file_list_generator.sh $FS_NAME $THRESHOLD $SERVER_NAME $INC_NUMBER $USERNAME >>$log_file 2>&1

## ~~~ copying the fsextension script to /tmp partition of remore server ~~~ ##
sudo cp -p $current_directory/fsextend_main.sh /tmp
exit_function "Unable to copy the fsextend_main.sh script to /tmp location"



perm_change
rm -f /tmp/$SERVER_NAME/big_file_list /tmp/$SERVER_NAME/big_file_list_1.html

cp -p /tmp/big_file_list /tmp/$SERVER_NAME/
cp -p /tmp/big_file_list_1.html /tmp/$SERVER_NAME/
exit_function  "temoporary files are not generated"


perm_change

## ~~~ Mail html body preparation ~~~ ##
sed -i 's/[ \t]/<TD BGCOLOR=00BFFF>/g' /tmp/$SERVER_NAME/big_file_list_1.html
sed -i 's/^/<TD BGCOLOR=00BFFF>/' /tmp/$SERVER_NAME/big_file_list_1.html
sed -i 's/^/<TR>\n/' /tmp/$SERVER_NAME/big_file_list_1.html


echo "<html>
<BR/>
<h3>BIG FILE LIST and OWNER INFO of $FS_NAME in $SERVER_NAME with $INC_NUMBER</h3>
<p></p>
<TABLE BORDER=1 CELLSPACING=3 CELLPADDING=3>
<TR>
<TD BGCOLOR=FA8072>Size(Mb)<TD BGCOLOR=FA8072>Owner<TD BGCOLOR=FA8072>Filename
`cat /tmp/$SERVER_NAME/big_file_list_1.html`
</TR>
</Table>
<BR/>
<html>" >/tmp/$SERVER_NAME/big_file_list_final.html

perm_change


## ~~~ Mail html body preparation ~~~ ##
flie_line_count=`cat /tmp/$SERVER_NAME/big_file_list | wc -l`
oracle_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'oracle|grid|dba' | wc -l`
netbackup_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'netbackup|tsm' | wc -l`
batch_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'ctmagent|ctmagen2|ctmagen3|controlm' | wc -l`
mft_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'cft|mft|gateway|sftp|transport' | wc -l`
sap_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'sapsys|sap|wp3adm|xfer' | wc -l`
op2_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'patrol' | wc -l`
op3_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'bpa' | wc -l`
tibco_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'tibco' | wc -l`
bigdata_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'splunk|hdfs|cloudera' | wc -l`
mw_bi_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'cognos|sap-pi|boxi|sas|Hyperion|Qliksense|Qlikview|ROAMBI' | wc -l`
mw_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'eroom|sharepoint|iis|ems|ftp' | wc -l`
mw_java_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'Websphere|JBOSS|tomcat|apache|http|weblogic|polaris|php|edcv2|documentum' | wc -l`
etl_line_count=`cat /tmp/$SERVER_NAME/big_file_list | egrep -i 'informatica|odi' | wc -l`

if [ $flie_line_count -gt 2 ] && [ $oracle_line_count -gt 0 ]; then
  mailsendto_1=GAHS.Oracle@accenture.com
  elif [ $flie_line_count -gt 2 ] && [ $netbackup_line_count -gt 0 ]; then
      mailsendto_2=GAHS.SAN@accenture.com
          elif [ $flie_line_count -gt 2 ] && [ $batch_line_count -gt 0 ]; then
              mailsendto_3=GAHS.BATCH@accenture.com
                  elif [ $flie_line_count -gt 2 ] && [ $sap_line_count -gt 0 ]; then
                       mailsendto_4=GAHS.SAP@accenture.com
                           elif [ $flie_line_count -gt 2 ] && [ $op2_line_count -gt 0 ]; then
                                mailsendto_5=GAHS.Production.Tool@accenture.com
                                    elif [ $flie_line_count -gt 2 ] && [ $op3_line_count -gt 0 ]; then
                                         mailsendto_6=GAHS.Production.Tool@accenture.com,monitoring.tools.L3support@sanofi.com
                                              elif [ $flie_line_count -gt 2 ] && [ $mft_line_count -gt 0 ]; then
                                                   mailsendto_7=GAHS.MFT@accenture.com
                                                       elif [ $flie_line_count -gt 2 ] && [ $tibco_line_count -gt 0 ]; then
                                                            mailsendto_8=GAHS.EAI@accenture.com
                                     elif [ $flie_line_count -gt 2 ] && [ $bigdata_line_count -gt 0 ]; then
                                           mailsendto_9=GAHS.BIGDATA@accenture.com
                                     elif [ $flie_line_count -gt 2 ] && [ $mw_bi_line_count -gt 0 ]; then
                                           mailsendto_10=GAHS.MIDDLEW.BI@accenture.com
                                     elif [ $flie_line_count -gt 2 ] && [ $mw_line_count -gt 0 ]; then
                                           mailsendto_11=GAHS.Middleware@accenture.com
                                     elif [ $flie_line_count -gt 2 ] && [ $etl_line_count -gt 0 ]; then
                                           mailsendto_12=GAHS.ETL@accenture.com
                                     elif [ $flie_line_count -gt 2 ] && [ $mw_java_line_count -gt 0 ]; then
                                           mailsendto_13=GAHS.MIDDLEW.JAVA@accenture.com

  else
      mailsendto_6=IO.SANOFI.L1-MONITORING@accenture.com,GAHS.UNIX@accenture.com
fi
#mailsendto=$mailsendto_1,$mailsendto_2,$mailsendto_3,$mailsendto_4,$mailsendto_5,$mailsendto_6,$mailsendto_7,$mailsendto_8,$mailsendto_9,${mailsendto_10},${mailsendto_11},${mailsendto_12},${mailsendto_13}
#mailsendcc=GAHS.Operations.Cent@accenture.com,GAHS.UNIX@accenture.com,IO.Sanofi.Automation@accenture.com
mailsendto=arindam.f.ghosh@accenture.com                                                      ## To list
mailsendcc=arindam.f.ghosh@accenture.com                                                      ## cc list



if [ $flie_line_count -gt 2 ]; then
$mailsender -e "my_hdr Content-Type: text/html" -s "UNIX04 ALERT: $INC_NUMBER || FILESYSTEM: $FS_NAME" $mailsendto -c $mailsendcc </tmp/$SERVER_NAME/big_file_list_final.html
fi

## ~~~ File system extension script execution in remote host ~~~ ##

sudo /bin/sh  $current_directory/fs_extension_deletion.sh $THRESHOLD $FS_NAME >>$log_file 2>&1
#percentage=`/bin/sh $current_directory/fs_actual_percentage.sh $FS_NAME | awk -F: '{print $2}'`
percentage=`df -k $FS_NAME | awk -F: '{print $NF}' | tail -1 | awk '{print $(NF-1)}'`

#echo "After optimization the current utilization of $FS_NAME is ${percentage}"

VAR1=$(echo "After optimization the current utilization of $FS_NAME is ${percentage}")
VAR2=$(cat $current_directory/logs/unix04_main.sh.log)

JSON_FORMAT=$( echo {'"type"': '"mixed"', '"value"': '"'$VAR1'"', '"log_value"' : '"'$VAR2'"'})
echo $JSON_FORMAT

