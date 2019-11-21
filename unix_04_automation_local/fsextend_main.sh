#!/bin/sh
#set -x
#################################################################
########                FS Extend upon free space availabel      ########
########                                Date : 18/01/2018        ########
########                Author :Shreekanta.jena@accenture.com    #######
########                Approver :                               ########
########                                                         ######
##################################################################
clear

        if [ -z "$1" ]; then
        echo "Please Supply FS Name (e.g sh script /FS-NAME FS-SIZE in mb == sh script /tmp 2048) "
                exit 1
        fi
FS_NAME_=$1

if [ -z "$2" ]; then
        echo "Please Supply FS Size you want to extend (e.g sh script /FS-NAME FS-SIZE in mb == sh script /tmp 2048) "
                exit 1
        fi
EXTEND_SIZE_=$2


OS_TYPE_=`uname`
        if [ "$OS_TYPE_" = "HP-UX" ];then
        INSTANCE_=`model | cut -d' ' -f5`
        if [ "$INSTANCE_" = "Virtual" ];then
        INSTANCE_TYPE_="VM"
        else
        INSTANCE_TYPE_="PHY"
        fi
        elif [ "$OS_TYPE_" = "Linux" ];then
        INSTANCE_=`sudo /usr/sbin/dmidecode -t system |grep Manufacturer|cut -d':' -f2`
        if [ "$INSTANCE_" = " Microsoft Corporation" ]
        then
           INSTANCE_TYPE_="VM"

        else
           INSTANCE_TYPE_="PHY"
         fi
        fi
#####echo $OS_TYPE_ and $INSTANCE_TYPE_





hpux_fsextend()
{

export PATH=/usr/bin/:/usr/sbin/:/opt/gvsd/bin/:/opt/hpvm/bin/:$PATH

        if [ "$OS_TYPE_" = "HP-UX" ];then
#LOCAL_FS_=`bdf -l  | awk '{if (NF==1) {line=$0;getline;sub(" *"," ");print line$0} else {print}}' | awk '{print $6}' | sed '1d'`
#echo "Local FS's are : "
#echo "======================================"
#bdf -l  | awk '{if (NF==1) {line=$0;getline;sub(" *"," ");print line$0} else {print}}' | awk '{print $6}' | sed '1d'
#echo "======================================"
#echo ""
#echo "Please Enter The FS Name which Needs to be Extended :"
#read FS_NAME_
#       if [ -z "$FS_NAME_" ]; then
#       echo "FS Name Can't be Blank "
#               exit 1
#       fi
        FS_EXISTANCE_=`df -lP|grep -w "$FS_NAME_"|wc -l`
        if [ $FS_EXISTANCE_ -eq 0 ];then
        echo "FS is Not mounted, please check as we are unable to find LV associated with FS $FS_NAME_"
        exit 1
        fi
######################Getting FS Details##########################
HOST_NAME_=`hostname`
OS_VERSION_=`uname -r`
LVNAME_=`df -lP $FS_NAME_ | awk '{if (NF==1) {line=$0;getline;sub(" *"," ");print line$0} else {print}}' | awk '{print $1}' | sed '1d'`
VGNAME_=`sudo /usr/sbin/lvdisplay $LVNAME_|grep "VG Name"|awk '{print $3}'`
VGVERSION_=`sudo /usr/sbin/vgdisplay $VGNAME_ | grep -i 'VG Version' | awk '{print $NF}'`
ONLINEJFS_=`sudo /usr/sbin/swlist -l product | grep -i jfs | grep -i online | wc -l`
POLICY_=`sudo /usr/sbin/lvdisplay $LVNAME_ | grep -i 'Allocation' | awk '{print $NF}'`
LV_PERM_=`sudo /usr/sbin/lvdisplay $LVNAME_ | grep -i 'LV Permission' | awk '{print $NF}'`
LVSTATUS_=`sudo /usr/sbin/lvdisplay $LVNAME_ | grep -i 'LV Status' | awk '{print $NF}'`
STRIPE_=`sudo /usr/sbin/lvdisplay $LVNAME_ | grep -i 'Stripes' | awk '{print $NF}'`
MIRRORCOPIES_=`sudo /usr/sbin/lvdisplay -v $LVNAME_ | grep -i 'Mirror copies' | awk '{print $NF}'`
PE_SIZE_=`sudo /usr/sbin/vgdisplay $VGNAME_ | grep -i 'PE Size' | awk '{print $NF}'`
FREE_PE_=`sudo /usr/sbin/vgdisplay $VGNAME_ | grep -i 'Free PE' | awk '{print $NF}'`
LV_SIZE_=`lvdisplay $LVNAME_| grep  'LV Size' | awk '{print $NF}'`
VG_FREESPACE_=`expr $FREE_PE_ \* $PE_SIZE_`
VG_EXTENDSIZE_=`expr $LV_SIZE_ + $EXTEND_SIZE_`
#VG_FREESPACEGB_=`expr $VG_FREESPACE_ / 1024`
###################################################################
                echo ""
                echo " Detailed output of FS $FS_NAME_"
                echo "-----------------------------------------------------------------"
                echo "HOSTNAME        =    $HOST_NAME_"
                echo "OS VERSION      =    $OS_VERSION_"
                echo "OS TYPE         =    $OS_TYPE_"
                echo "INSTANCE        =    $INSTANCE_TYPE_ "
                echo "FS NAME         =    $FS_NAME_"
                echo "VG NAME         =    $VGNAME_"
                echo "LV NAME         =    $LVNAME_"
                echo "VG VERSION      =    $VGVERSION_"
                echo "FREE SPACE IN $VGNAME_ =   $VG_FREESPACE_ MB"
                echo "-----------------------------------------------------------------"
                echo ""
                #echo "Please Enter the Size in GB to extend $FS_NAME_ Should be Less than $VG_FREESPACE_ MB  :"
#read EXTEND_SIZE_
        #if [ -z "$EXTEND_SIZE_" ]; then
        #echo "Size Name Can't be Blank "
        #       exit 1
        #fi
#EXTEND_SIZECHECK_=`echo $EXTEND_SIZE_ '>' $VG_FREESPACEGB_ |bc -l`
#####
#EXTEND_SIZE_1=`expr $EXTEND_SIZE_ \* 1024`
VG_EXTENDSIZE_1=`echo $VG_EXTENDSIZE_ |sed 's/$/M/'`
echo ""
        if [[ "$EXTEND_SIZE_" -ge "$VG_FREESPACE_" ]]; then
        echo "Required Size is Greater Than Free Space."
        echo "Please Extend The Disk From SAN :"
        echo ""
        echo "Details Are :"
        echo "Host Name: $HOST_NAME_"

        ###############STARTING OF WWN LIST#############
        if [[ $INSTANCE_TYPE_ = "VM" ]]; then
        echo ""
        echo "WWN's"
        #HPVMDEVINFO_=`which hpvmdevinfo`

        for gvsd in `/usr/bin/sudo hpvmdevinfo -M | awk -F: '/npiv/ {print $NF}'`; do
          sudo /opt/gvsd/bin/gvsdmgr get_info -D $gvsd | awk '/Port WWN/ {print $NF}'
        done
        echo ""
        echo "Disk Details of $VGNAME_"
        echo ""

        for diskinfo in `/usr/bin/sudo /usr/sbin/vgdisplay -v $VGNAME_ |grep -i "PV Name" |awk '{print $NF}'| cut -d "_" -f1|awk -F'/' '{print $NF}'`
        do
        sudo /usr/sbin/scsimgr -p get_attr all_lun -a device_file -a wwid -a vid -a state | grep rdisk |grep -i "$diskinfo"
        done
        elif [[ $INSTANCE_TYPE_ = "PHY" ]]; then
        echo ""
        echo "WWN's"
        for wwns in `sudo /usr/sbin/ioscan -fnkC fc|grep "/dev/"|grep fcd`; do  fcdutil $wwns|grep -i "N_Port Port World Wide Name"|awk '{print $NF}'; done
        echo ""
        echo "Disk Details of $VGNAME_"
        echo ""

        for diskinfo in `sudo /usr/sbin/vgdisplay -v $VGNAME_ |grep -i "PV Name" |awk '{print $NF}'| cut -d "_" -f1|awk -F'/' '{print $NF}'`
        do
        sudo /usr/sbin/scsimgr -p get_attr all_lun -a device_file -a wwid -a vid -a state | grep rdisk |grep -i "$diskinfo"
        done

        else
        echo "Instance is not supported "
        fi
        #################END OF WWN LIST###############
        elif [[ "ONLINEJFS_" = "0" ]]; then

        echo "Online FS extension is not possible"
        elif [[ "$POLICY_" = "strict/contiguous" ]]; then
        echo "Filesystem can't be extended as lvm PE allocation policy is $POLICY_"
        elif [[ "$LV_PERM_" = "read-only" ]]; then
        echo "File system is readonly; Please check before unmounting it and run a fsck"
        elif [[ "$LVSTATUS_" != "available/syncd" ]]; then
        echo "Some problem with the logical volume, either stale PE or Inactive"
        else
#        echo "Working"
sudo lvextend -L $VG_EXTENDSIZE_ $LVNAME_
sudo fsadm -F vxfs -b $VG_EXTENDSIZE_1 $FS_NAME_
        if [ $? -ne 0 ]; then
        echo "FS $FS_NAME_ is not extended"
        else
        echo "FS $FS_NAME_ is extended by $EXTEND_SIZE_ MB"
        fi
        fi
        fi
}

linux_fsextend()
{
#clear
export PATH=/sbin:/bin:/usr/bin:$PATH
#

FS_EXISTANCE_=`df -lP|grep "$FS_NAME_"|wc -l`
        if [ $FS_EXISTANCE_ -eq 0 ];then
        echo "FS is Not mounted, please check as we are unable to find LV associated with FS $FS_NAME_"
        exit 1
        fi

#echo "Local FS's are : "
#echo "======================================"
#df -l |awk '{if (NF==1) {line=$0;getline;sub(" *"," ");print line$0} else {print}}' | awk '{print $6}' | sed '1d'
#echo "======================================"
#echo "Please enter the FS Name (e.g /data):"
#read FS_NAME_
#       if [ -z "$FS_NAME_" ]; then
#       echo "FS Name Can't be Blank "
#               exit 1
#       fi
HOST_NAME_=`hostname`
OS_VERSION_=`sudo cat /etc/os-release  | grep -iw VERSION |awk -F= '{print $2}'`

whereis lvdisplay | awk '{print $2}' | grep "lvdisplay$" >/dev/null 2>&1
if [ $? -eq 0 ]; then lvdisplay=`whereis lvdisplay | awk '{print $2}' | grep "lvdisplay$"`; else echo "lvdisplay command not found"; exit 1; fi

whereis lvextend | awk '{print $2}' | grep "lvextend$" >/dev/null 2>&1
if [ $? -eq 0 ]; then lvextend=`whereis lvextend | awk '{print $2}' | grep "lvextend$"`; else echo "lvextend command not found"; exit 1; fi

whereis resize2fs | awk '{print $2}' | grep "resize2fs$" >/dev/null 2>&1
if [ $? -eq 0 ]; then resize2fs=`whereis resize2fs | awk '{print $2}' | grep "resize2fs$"`; else echo "resize2fs command not found"; exit 1; fi

LV_NAME_=`sudo df -Pl "$FS_NAME_"|grep -v "Filesystem"|awk '{print $1}'`
VG_NAME_=`sudo $lvdisplay $LV_NAME_ |grep "VG Name"|awk '{print $3}' 2>/dev/null`
CURRENT_LVSIZE_=`sudo $lvdisplay $LV_NAME_ |grep "LV Size"|awk '{print $3 $4}' 2>/dev/null`
#VG_FREESIZE_=`sudo vgs|grep "$VG_NAME_" |awk '{print $7}'|tr -d [A-Z][a-z]|sed 's/[^.0-9][^.0-9]*/ /g'|tail -1 2>/dev/null`
#VG_FREESIZEMB_=$(echo $VG_FREESIZE_*1024 | bc)
whereis vgs | awk '{print $2}' | grep "vgs$" >/dev/null 2>&1
if [ $? -eq 0 ]; then vgs=`whereis vgs | awk '{print $2}' | grep "vgs$"`; else echo "vgs command not found"; exit 1; fi
VG_FREESIZE_=`sudo $vgs 2>/dev/null|grep "$VG_NAME_" |awk '{print $7}'|awk '{print tolower($0)}'|sed 's/^<//'`  ## Modified by Arindam to handle vgs output properly

if [ $VG_FREESIZE_ = 0 ]; then
   VG_FREESIZE=0
 else
    eval VG_FREESIZE=`sudo $vgs 2>/dev/null|grep "$VG_NAME_" |awk '{print $7}'|sed 's/.$//'|sed 's/^<//'`
 fi

sudo whereis bc | awk '{print $2}' | grep 'bc$' >/dev/null 2>&1    ##Installing backage bc where not installed
  if [ $? -ne 0 ]; then sudo apt install bc -y >/dev/null 2>&1; fi
whereis bc | awk '{print $2}' | grep 'bc$' >/dev/null 2>&1
  if [ $? -ne 0 ]; then echo "bc not installed with apt, please loginto the server and check"; exit 1; fi

if [ `echo $VG_FREESIZE_ | tail -c 2` = "g" ] || [ `echo $VG_FREESIZE_ | tail -c 2`  = "G" ] && [ $VG_FREESIZE != 0 ]; then
   VG_FREESIZEMB_=$(echo $VG_FREESIZE*1024 | bc)
 elif [ `echo $VG_FREESIZE_ | tail -c 2`  = "m" ] || [ `echo $VG_FREESIZE_ | tail -c 2`  = "M" ] && [ $VG_FREESIZE != 0 ]; then
     VG_FREESIZEMB_=`echo $VG_FREESIZE`
 elif [ `echo $VG_FREESIZE_ | tail -c 2`  = "t" ] || [ `echo $VG_FREESIZE_ | tail -c 2`  = "T" ] && [ $VG_FREESIZE != 0 ]; then
     VG_FREESIZEMB_=$(echo $VG_FREESIZE*1024*1024 | bc)
 elif  [ $VG_FREESIZE = 0 ]; then
     VG_FREESIZEMB_=0
    elif [ -z $VG_FREESIZE_ ]; then
           echo "Unable to print free space in VG: $VG_NAME_"
           exit 1
        else
        echo "This script is supported for space calculation in mb, gb and tb, actual value of vg_free_space is $VG_FREESIZE_"
                exit 1
 fi

 ## Modified by Arindam to handle vgs output properly
###############################################################################
        echo ""
        echo "Detailed output of FS $FS_NAME_"
        echo "--------------------------------------------"
        echo "HOSTNAME      =      $HOST_NAME_"
        #echo "OS VERSION    =      $OS_VERSION_"
        echo "OS TYPE       =      $OS_TYPE_"
        echo "INSTANCE      =      $INSTANCE_TYPE_ "
        echo "FS NAME       =      $FS_NAME_"
        echo "VG NAME       =      $VG_NAME_"
        echo "LV NAME       =      $LV_NAME_"
        echo "LV SIZE       =  $CURRENT_LVSIZE_"
	echo "REQUIRED SAPCE = $EXTEND_SIZE_ MB"
        echo "FREE SPACE IN VG = $VG_FREESIZEMB_ MB"
        echo "--------------------------------------------"
        #echo "Please Enter The size in GB you want to increase $FS_NAME Should be less Than $VG_FREESIZE_ GB : "
        #read EXTEND_SIZE_
#
EXTEND_SIZEMB_=`echo $EXTEND_SIZE_ |sed 's/$/M/'`
        if [ -z "$EXTEND_SIZE_" ]; then
        echo "Size Name Can't be Blank "
                exit 1
                fi
                #
                VG_FREESIZEMB_1=`echo $VG_FREESIZEMB_ | cut -d. -f1`

        if [ "$EXTEND_SIZE_" -gt "$VG_FREESIZEMB_1" ]
 then
        echo "Required Size is Greater Than Free Space."
        echo "Please assign New Disk From SAN :"
        echo ""
        echo "Details Are :"
        echo "Host Name: $HOST_NAME_"
        echo ""
        if [ $INSTANCE_TYPE_ = "PHY" ]; then
        echo "WWN's "
        echo ""
        for wwns in `ls -l /sys/class/fc_host|grep -v total |awk '{print $9}'`
         do
        cat /sys/class/fc_host/$wwns/port_name
        done
        elif [ $INSTANCE_TYPE_ = "VM" ]; then
        echo "$HOST_NAME_ is a Linux VM , Please assign new disk from VSphere."
        else
        echo "Not Getting Instance Type , Please check once with L3 Team."
        fi
        else
     sudo $lvextend -L +$EXTEND_SIZEMB_ $LV_NAME_
    sudo $resize2fs $LV_NAME_
 if [ $? -ne 0 ]; then
 echo "FS $FS_NAME_ is not extended"
 else
 echo "FS $FS_NAME_ is extended by $EXTEND_SIZE_ MB"
 fi
#        CURRENT_LVSIZE_=`sudo $lvdisplay $LV_NAME_ |grep "LV Size"|awk '{print $3 $4}' 2>/dev/null`
#       echo "Extending LV $LV_NAME_ by $EXTEND_SIZE_ MB , Current Size = $CURRENT_LVSIZE_"
#
        fi
}


aix_fsextend()
{

if [ "$OS_TYPE_" = "AIX" ];then

export PATH=/usr/bin:/usr/sbin:$PATH

FS_EXISTANCE_=`mount | grep jfs |grep "$FS_NAME_"|wc -l`
        if [ $FS_EXISTANCE_ -eq 0 ];then
        echo "FS is Not mounted, please check as we are unable to find LV associated with FS $FS_NAME_"
        exit 1
        fi
###############################
HOST_NAME_=`hostname`
OS_VERSION_=`oslevel -s`
LV_NAME_=`df -P $FS_NAME_|grep "$FS_NAME_" |awk '{print $1}'|awk -F'/' '{print $NF}'`
LV_STATE_=`sudo lslv $LV_NAME_ |grep "LV STATE:"|awk '{print $NF}'`
VG_NAME_=`sudo lslv $LV_NAME_ |grep -i "VOLUME GROUP:" |awk '{print $NF}'`
LV_COPIES_=`sudo lslv $LV_NAME_  |grep "COPIES:"|awk '{print $2}'`
LV_PERMISSION_=`sudo lslv $LV_NAME_ |grep -i "PERMISSION:" |awk '{print $NF}'`
LV_POLICY_=`sudo lslv $LV_NAME_  |grep "SCHED POLICY:" |awk '{print $NF}'`
TOTAL_PP_=`sudo lslv $LV_NAME_ |grep -i "PP SIZE:"|awk '{print $6}'`
MAX_LP_=`sudo lslv $LV_NAME_ |grep -i "MAX LPs:"|awk '{print $3}'`
CURRENT_LP_=`sudo lslv $LV_NAME_ |grep -i "LPs:"|grep -v MAX |awk '{print $2}'`
VG_PPSIZE_=`sudo lsvg $VG_NAME_ |grep "PP SIZE:" |awk '{print $6}'`
VG_FREEPP_=`sudo lsvg $VG_NAME_ |grep "FREE PPs:" |awk '{print $6}'`
VG_STALEPP_=`sudo lsvg $VG_NAME_ |grep "STALE PPs:" |awk '{print $NF}'`
CURRENTLV_SIZE_=`expr $CURRENT_LP_ \* $VG_PPSIZE_`
MAXINC_SIZE_=`expr $MAX_LP_ \* $VG_PPSIZE_`

EXTEND_SIZEMB_=`echo $EXTEND_SIZE_ |sed 's/$/M/'`

LVSIZE_EXTANDABLE_=`expr $MAX_LP_ \* $VG_PPSIZE_`

#############################################
                echo "       Detailed output of FS $FS_NAME_    "
                echo "---------------------------------------------------------------"
                echo "HOSTNAME        =    $HOST_NAME_"
                echo "OS VERSION      =    $OS_VERSION_"
                echo "OS TYPE         =    $OS_TYPE_"
                echo "FS NAME         =    $FS_NAME_"
                echo "VG NAME         =    $VG_NAME_"
                echo "LV NAME         =    $LV_NAME_"
                echo "LV PERMISSION   =    $LV_PERMISSION_"
                echo "FREE SPACE IN $VGNAME_     =   $MAXINC_SIZE_ MB"
                echo "EXPANDABLE SIZE DUE TO LP  =   $LVSIZE_EXTANDABLE_"
                echo "----------------------------------------------------------------"
                echo ""
#############################################
if [[ "$EXTEND_SIZE_" -ge "$CURRENTLV_SIZE_" ]]; then
        echo "Required Size is Greater Than Free Space."
        echo "Please assign New Disk From SAN."
        echo ""
        echo "Details Are :"
        echo ""
        echo "WWN's"
        echo ""
        for fcs in `sudo lsdev -Cc adapter | grep fcs|awk '{print $1}'`
        do
        lscfg -vl $fcs|grep "Network Address"
        done
        echo "Host Name: $HOST_NAME_"
        echo ""
        echo "DISK DETAILS ARE :"
        echo ""
        sudo lspv -u |grep -i "$VG_NAME_"
        echo ""
        elif [[ "$EXTEND_SIZE_" -ge "$LVSIZE_EXTANDABLE_" ]]; then
        echo "As MAX LPs value is lower than Extend size , we need to change the MAX LPs."
        LVEXTEND_LP_=`expr $EXTEND_SIZE_ / $VG_PPSIZE_`
        #
        LVEXTEND_LP_1=`expr $LVEXTEND_LP_ + $CURRENT_LP_`
        #
        if [[ "$LVEXTEND_LP_1" -ge "$MAX_LP_" ]]; then
        echo "We are Unable to Extend LPs"
        else
        #
        echo "LP Extended upto $LVEXTEND_LP_1"
        chlv -x $LVEXTEND_LP_1 $LV_NAME_
        fi
        else
        sudo chfs -a size=+$EXTEND_SIZEMB_ $FS_NAME_
        #echo "Working"
        if [ $? -ne 0 ];then
        echo "ERROR:   FS $FS_NAME_ Not Extended "
        else
        echo "FS $FS_NAME_ has been extended by $EXTEND_SIZE_   MB"
fi
fi
fi

}
if [ "$OS_TYPE_" = "HP-UX" ];then
hpux_fsextend
elif [ "$OS_TYPE_" = "Linux" ];then
linux_fsextend
elif [ "$OS_TYPE_" = "AIX" ];then
aix_fsextend
else
echo "OS Not Supported"
fi
