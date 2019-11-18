#!/bin/sh
##Script Name:   fs_extension_deletion.sh $FS_NAME $THRESHOLD

PATH=/sbin:/bin:/usr/bin:/usr/sbin:$PATH


THRESHOLD=$1
FS_NAME=$2
os_flavor=`uname`
current_directory="$(dirname "$0")"
logfile=/usr/local/scripts/unix_04_automation_local/logs/unix04_main.sh.log

FSACTUAL_F()     {

if [ ${os_flavor} = SunOS ]; then

FSACTUAL=`df -k $FS_NAME | awk -F"%" '{print $1}' | tail -1 | awk '{print substr($0,length($0)-3)}' |sed 's/^[ *\t]//'`       #  Checking FS Utilization
FS_SIZE=`df -k $FS_NAME | sed '1d'|awk '{printf "%.0f\n", $2/1024}'`

else

FSACTUAL=`df -k $FS_NAME | awk -F"%" '{print $1}' | tail -1 | awk '{print substr($0,length($0)-3)}' |sed 's/^[ *\t]//'`       #  Checking FS Utilization
FS_SIZE=`df -kP $FS_NAME | tail -1 | awk '{printf "%.0f\n", $2/1024}'`

fi

if [ ${os_flavor} = Linux ]; then
if [ ${FSACTUAL} -gt ${THRESHOLD} ]; then
if [ $FS_SIZE -gt 5000 ]; then	
FS_TO_EXTEND_PERCENTAGE=$( echo ${FSACTUAL} + 5 - ${THRESHOLD} | bc )
else
   FS_TO_EXTEND_PERCENTAGE=$( echo ${FSACTUAL} + 20 - ${THRESHOLD} | bc )
   fi
##How much space shall be increased
FS_TO_EXTEND=$( echo $FS_SIZE \ * $FS_TO_EXTEND_PERCENTAGE / 100 | bc )
FS_TO_EXTEND=`echo $FS_TO_EXTEND | awk -F. '{print $1}'`
else
echo "$FS_NAME filesystem utilization is below threshold now"
exit 1
fi

else

if [ ${FSACTUAL} -gt ${THRESHOLD} ]; then
if [ $FS_SIZE -gt 5000 ]; then
FS_TO_EXTEND_PERCENTAGE=$( echo ${FSACTUAL} + 5 - ${THRESHOLD} | bc )
else
   FS_TO_EXTEND_PERCENTAGE=$( echo ${FSACTUAL} + 20 - ${THRESHOLD} | bc )
   fi
##How much space shall be increased
FS_TO_EXTEND=$( echo $FS_SIZE \ * $FS_TO_EXTEND_PERCENTAGE / 100 | bc )
FS_TO_EXTEND=`echo $FS_TO_EXTEND | awk -F. '{print $1}'`
else
echo "$FS_NAME filesystem utilization is below threshold now"
exit 1
fi
fi
}


#if [ $os_flavor = Linux ]; then
#mount -o remount,rw,exec /tmp >/dev/null 2>&1
#fi


var_fs_handler()   {

echo "zipping 10 days older log files..."
#sudo find $FS_NAME -xdev -type f -name '*.log*' -mtime +10 -size +5000 -exec gzip -3 {} \; 2>/dev/null
sudo find $FS_NAME -xdev -type f -name '*.log*' ! \( -name "*.gz" \) ! \( -name "*.Z" \) -mtime +10 -size +5000 -exec gzip -3 -S "_`date '+%Y%m%d%H%M'`.gz"  {} \; 2>/dev/null &

if [ $os_flavor = Linux ]; then
        yum clean all 2>/dev/null
        sudo tail -500 /var/mail/root >/var/mail/root_bkp_`date '+%Y%m%d%H%M'` >/dev/null 2>&1
        echo "truncating /var/mail/root"
        sudo >/var/mail/root 2>/dev/null
        FSACTUAL_F
    if [[ $FSACTUAL -gt ${THRESHOLD} ]];then
        echo "Extending the FS $FS_NAME"
        sh /tmp/fsextend_main.sh $FS_NAME $FS_TO_EXTEND
        fi

     elif [ $os_flavor = "HP-UX" ]; then
        sudo tail -500 /var/mail/root >/var/mail/root_bkp_`date '+%Y%m%d%H%M'` >/dev/null 2>&1
        echo "truncating /var/mail/root"
        sudo >/var/mail/root 2>/dev/null
        FSACTUAL_F
    if [[ $FSACTUAL -gt ${THRESHOLD} ]];then
        echo "Extending the FS $FS_NAME"
        sh /tmp/fsextend_main.sh $FS_NAME $FS_TO_EXTEND
        fi

        elif [ $os_flavor = AIX ]; then
            sudo tail -500 /var/spool/mail/root > /var/spool/mail/root_bkp_`date '+%Y%m%d%H%M'` >/dev/null 2>&1
            echo "truncating /var/spool/mail/root"
            sudo >/var/spool/mail/root 2>/dev/null
            FSACTUAL_F
            if [[ $FSACTUAL -gt ${THRESHOLD} ]];then
            echo "Extending the FS $FS_NAME"
            sudo sh /tmp/fsextend_main.sh $FS_NAME $FS_TO_EXTEND
        fi

fi

}


other_fs_handler()    {

echo "zipping 10 days older log files..."
#sudo find $FS_NAME -xdev -type f -name '*.log*' -mtime +10 -size +5000 -exec gzip -3 {} \; 2>/dev/null
sudo find $FS_NAME -xdev -type f -name '*.log*' ! \( -name "*.gz" \) ! \( -name "*.Z" \) -mtime +10 -size +5000 -exec gzip -3 -S "_`date '+%Y%m%d%H%M'`.gz"  {} \; 2>/dev/null &
   
FSACTUAL_F
if [ $FSACTUAL -gt ${THRESHOLD} ]; then
echo "Extending the FS $FS_NAME"
sudo sh /tmp/fsextend_main.sh $FS_NAME $FS_TO_EXTEND
fi

}

tmp_fs_handler()    {

echo "Deleting 180days older files"
sudo find /tmp -xdev -type f -mtime +180 -size +50000 -exec rm -f {} \; 2>/dev/null
FSACTUAL_F	
if [ $FSACTUAL -gt ${THRESHOLD} ]; then
    echo "Extending the FS /tmp"
    sudo sh /tmp/fsextend_main.sh $FS_NAME $FS_TO_EXTEND
fi

}

rest_fs_handler()     {

FSACTUAL=`df -k $FS_NAME | awk -F"%" '{print $1}' | tail -1 | awk '{print substr($0,length($0)-3)}' |sed 's/^[ *\t]//'`       #  Checking FS Utilization
echo "===============================================================================================================================">>$logfile
echo "Before zipping the log files current utilization is ${FSACTUAL}%" >>$logfile 
echo >>$logfile
echo "Zipping the day older log files only if exists" >>$logfile
echo >>$logfile
#sudo find $FS_NAME -xdev -type f -name '*.log*' -mtime +10 -size +5000 -exec gzip -3 {} \; 2>/dev/null
sudo find $FS_NAME -xdev -type f -name '*.log*' -mtime +1 -size +5000 -exec gzip -3 -S "_`date '+%Y%m%d%H%M'`.gz"  {} \; >>$logfile 2>&1
FSACTUAL=`df -k $FS_NAME | awk -F"%" '{print $1}' | tail -1 | awk '{print substr($0,length($0)-3)}' |sed 's/^[ *\t]//'`       #  Checking FS Utilization
echo >>$logfile
echo "After zipping the log files current utilization is ${FSACTUAL}%" >>$logfile 
echo >>$logfile
echo "Zipped log files are: ">>$logfile
sudo find  $FS_NAME -xdev -type f -name '*.gz' -exec ls -lrth {} \; >>$logfile

#if [ $FSACTUAL -gt ${THRESHOLD} ]; then
#echo "Still the FS utilization is high"
#else
#echo "FS utilization is below threshold now"
#fi 

}


echo
while [ -n "$2" ]
do
case "$2" in
/root)
      rest_fs_handler 
;;
/data)
      rest_fs_handler
;;
/)
      rest_fs_handler
;;
/oradata)
       rest_fs_handler
;;
*)
      rest_fs_handler
;;
esac
shift
done


#percentage=`/bin/sh $current_directory/fs_actual_percentage.sh $FS_NAME | awk -F: '{print $NF}'`
percentage=`df -k $FS_NAME | awk -F: '{print $NF}' | tail -1 | awk '{print $(NF-1)}'`

#echo "After optimization the current utilization of $FS_NAME is $percentage"


VAR=$(echo "After optimization the current utilization of $FS_NAME is $percentage")

JSON_FORMAT=$(echo {'"type"' : '"plainText"', '"value"': '"'$VAR'"'})

echo $JSON_FORMAT
