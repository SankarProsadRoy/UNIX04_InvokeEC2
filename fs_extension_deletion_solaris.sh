#!/bin/sh

##Script Name:   fs_extension_deletion.sh $FSACTUAL $FS_NAME
PATH=/sbin:/bin:/usr/bin:/usr/sbin:$PATH

THRESHOLD=$1
FS_NAME=$2
os_flavor=`uname`



other_fs_handler()    {
echo "zipping 10 days older log files..."
#dzdo find $FS_NAME -xdev -type f -name '*.log*' -mtime +10 -size +5000 -exec gzip -3 {} \; 2>/dev/null
dzdo find $FS_NAME -xdev -type f -name '*.log*' ! \( -name "*.gz" \) ! \( -name "*.Z" \) -mtime +10 -size +5000 -exec gzip -3 -S "_`date '+%Y%m%d%H%M'`.gz"  {} \; 2>/dev/null &
FSACTUAL=`df -k $FS_NAME | awk -F"%" '{print $1}' | tail -1 | awk '{print substr($0,length($0)-3)}' |sed 's/^[ *\t]//'`       #  Checking FS Utilization
    if [ ${FSACTUAL} -lt ${THRESHOLD} ]; then
      echo "$FS_NAME filesystem utilization is below threshold now"
      exit 1
    else
       echo "Still the FS utilization is high"
    fi

}


tmp_fs_handler()    {

 echo "Deleting 180days older files"
dzdo find /tmp -xdev -type f -mtime +180 -size +50000 -exec rm -f {} \; 2>/dev/null
FSACTUAL=`df -k $FS_NAME | awk -F"%" '{print $1}' | tail -1 | awk '{print substr($0,length($0)-3)}' |sed 's/^[ *\t]//'`       #  Checking FS Utilization
if [ ${FSACTUAL} -lt ${THRESHOLD} ]; then
    echo "$FS_NAME filesystem utilization is below threshold now"
exit 1
else
    echo "Still the FS utilization is high"
fi

}



echo
while [ -n "$2" ]
do
case "$2" in
*)
        other_fs_handler
;;
esac
shift
done

exit 0
