#!/bin/bash

# Declaring variable

USER_NAME=$(id -un)
DATE=$(date +%Y-%m-%d)
SSH_LOGIN=$(ssh -q -o ConnectTimeout=30 -o 'StrictHostKeyChecking no')

# Function for IpAddress 

function ipaddress ()
{
 read -p 'Enter the IP Address of server to perform the action: ' IP
 if [[ -z "${IP}" ]]
 then
   echo "No IP Address found, Please provide IP Address of server to perform the action"
   ipaddress
 fi
}

# function for extending logical volume

function lvextend ()
{
 ipaddress
 read -p 'Enter the File System name to extend [ Ex: /dev/mapper/vg_01-lv_02]: ' FS
 read -p 'Enter the size to extend ${FS} [ Ex: 2G ]: ' SZ
 ssh -q -o ConnectTimeout=30 -o 'StrictHostKeyChecking no' -T "${USER_NAME}"@"${IP}" FS="${FS}" SIZE="${SZ}" 'bash -s' << 'ENDSSH'
 CHK_FS=$(sudo df -hT | grep ${FS}) > /dev/null 2>&1
 CHK_RESULT=$(echo ${?})
 if [[ "${CHK_RESULT}" -eq 0 ]]
    then
      sudo lvextend -L +"${SIZE}" "${FS}" > /dev/null 2>&1
        if [[ "${?}" -eq 0 ]]
           then 
             sudo resize2fs "${FS}"  > /dev/null 2>&1
               if [[ "${?}" -eq 0 ]]
                  then
                    echo -ne "\n";echo "Logical volume ${FS} extended succesfully"
                    echo -ne "\n";echo "Old File system Size";echo "====================" 
                    echo ; echo "Filesystem              Type      Size  Used Avail Use% Mounted on"
                    echo "------------------------------------------------------------------"
                    echo "${CHK_FS}"
                    echo -ne "\n";echo "New File system Size";echo "====================" 
                    echo ; echo "Filesystem              Type      Size  Used Avail Use% Mounted on"
                    echo "------------------------------------------------------------------"
                    sudo df -hT | grep "${FS}" 
                  else
                    echo "Logical volume ${FS} not extended succesfully"
               fi
            else
              echo "lvextend not happened successfully. Check the logs"
              exit 1
        fi
     else
       echo "File System ${FS} not found on system"
 fi
ENDSSH
}

# function for extending volume group

function vgextend ()
{
 ipaddress
 read -p 'Enter the Volume group Name to extend: ' VG
 read -p "Enter the physical volume Disks to extend in the ${VG} group [ Ex: /dev/sdb,/dev/sdc ]: " PVDS
 ssh -q -o ConnectTimeout=30 -o 'StrictHostKeyChecking no' -T "${USER_NAME}"@"${IP}" UN="${USER_NAME}" VG="${VG}" IP="${IP}" PVDS="${PVDS}" 'bash -s' << 'ENDSSH'
 IFS=',' read -ra StringValue<<< "${PVDS}"
 date=$(date +%Y-%m-%d)
 err=0 
 for i in "${StringValue[@]}"
     do
       PV_CHECK=$(sudo /usr/sbin/pvdisplay ${i} | grep "Allocatable" | xargs | awk -F " " {'print $2'})
         if [[ "${PV_CHECK}" = "NO" ]]
            then
                sudo /usr/sbin/vgdisplay "${VG}" > /dev/null 2>&1
                VGRESULT=$(echo ${?})
                  if [[ "${VGRESULT}" -eq "0" ]]
                      then
                         sudo /usr/sbin/vgextend "${VG}" "${i}" > /dev/null 2>&1
                             if [[ "${?}" -eq "0" ]]
                                then 
                                   echo "Physical volume ${i} is successfully added to the volume group ${VG}." | tee -a lvm.log_"${date}"
                                else
                                   echo "Physical volume ${i} is not successfully added to the volume group ${VG}." 
                                   err=1
                             fi
                      else
                        echo "Volume group ${VG} not found" |  tee -a lvm.log_"${date}"
                        exit 1
                  fi
             else
               echo "Request Not succeded, Physical volume ${i} is already Allocated/Not found" | tee -a lvm.log_"${date}"
               exit 1
         fi
      done
 if [[ "${err}" -eq "1" ]]
    then
      echo "Volume group ${VG} is not successfully extended"
    else
      echo "Volume group ${VG} is successfully extended" | tee -a lvm.log_"${date}"
      echo "==========================================="
      echo "sudo vgs"
 fi
     
ENDSSH
}

# Function for creating physical volume

function pvcreate ()
{
  ipaddress
  read -p 'Enter the Ticket/Change number: ' CN
  read -p 'Enter the Disks to create PV [ If multiple disks to add ,then provide with comma seperated values Ex: /dev/sdb,/dev/sdc ]: ' PVD 
  ssh -q -o ConnectTimeout=30 -o 'StrictHostKeyChecking no' -T "${USER_NAME}"@"${IP}" UN="${USER_NAME}" CN="${CN}" IP="${IP}" PV="${PVD}" 'bash -s' << 'ENDSSH'
  IFS=',' read -ra StringValue<<< "${PV}"
  date=$(date +%Y-%m-%d)
  echo -ne "Username: ${UN} \nIPAddress: ${IP} \nChangeNumber: ${CN} \nDisk Name: ${PV} \n" >  lvm.log_"${date}"
  for i in "${StringValue[@]}"
      do
          sudo /usr/sbin/pvdisplay "${i}" > /dev/null 2>&1
           RESULT1=$(echo ${?})
             if [[ "${RESULT1}" -ne "0" ]]
                then
                  sudo /usr/bin/df -hT | grep -i "${i}" > /dev/null 2>&1
                  RESULT2=$(echo ${?})
                    if [[ "${RESULT2}" -ne "0" ]]
                       then
                          sudo /usr/sbin/pvcreate "${i}" &>> lvm.log_"${date}"
                             if [[ "${?}" -eq "0" ]]
                                then 
                                   echo "Physical volume ${i} successfully created."
                                else
                                   echo "Physical volume ${i} not created successfully."
                             fi
                       else
                          echo "Request Not succeded, Device ${i} is in use" | tee -a  lvm.log_"${date}"
                    fi
                else
                  echo "Request Not succeded, Device ${i} is in use" | tee -a lvm.log_"${date}"
             fi
      done
ENDSSH
}


# Function for displaying the available free disks to create PV's

function showdisks()
{
     ipaddress
     ssh -q -o ConnectTimeout=30 -o 'StrictHostKeyChecking no' -T "${USER_NAME}"@"${IP}" IP_VAR="${IP}"  'bash -s' << 'ENDSSH'
     echo ""; echo "NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT - Server - ${IP_VAR}"; echo "================================================================";
     SHOW_DISKS=$(sudo /usr/bin/lsblk | sed 1d | grep "disk" | awk -F " " '{print $1}')
     for i in $(echo "${SHOW_DISKS}" | tr ' ' '\n')
      do
          sudo /usr/sbin/pvdisplay /dev/"${i}" > /dev/null 2>&1
           RESULT1=$(echo ${?})
             if [[ "${RESULT1}" -ne "0" ]]
                then
                  sudo /usr/bin/df -hT | grep -i "/dev/${i}" > /dev/null 2>&1
                  RESULT2=$(echo ${?})
                    if [[ "${RESULT2}" -ne "0" ]]
                       then
                          DISK_FOUND=$(sudo fdisk -l | grep ${i} | awk -F " " {'print $2 $3 $4'})
                          echo "${DISK_FOUND}"
                       else
                          echo "Device $i is in use" > /dev/null 2>&1
                    fi
                else
                  echo "Device $i is in use" > /dev/null 2>&1
             fi
      done
if [[ -z "${DISK_FOUND}" ]]
then
echo "No Disk Found"
echo -ne "\n"
fi

ENDSSH
}


# Fucntion for displaying the current pv's lv's and vg's

function lvmdisplay()
{
   ipaddress
   ssh -q -o ConnectTimeout=30 -o 'StrictHostKeyChecking no' -T "${USER_NAME}"@"${IP}" IP_VAR="${IP}" 'bash -s' << 'ENDSSH'
   echo ""
   echo  "Displaying the current pv's lv's and vg's - ${IP_VAR}"
   echo "=========================================================";echo ""
   sudo pvs ; echo "=============================================" ; sudo vgs ; echo "============================================="  ; sudo lvs ; echo "============================================="; echo ""
ENDSSH
}


# Testing User Privilege 

if [[ "${USER_NAME}" = "root" ]]; 
then
   echo "Run the command with a non-root User"
   exit 1
fi

while :
  do
     clear
                        echo ""
                        echo ""
                        echo "                      LINUX LOGICAL VOLUME ADMINISTRATION"
                        echo ""
                        echo " 1. Display existing LV's PV's VG's info"
                        echo ""
                        echo " 2. Display the devices available to create PV's"
                        echo ""
                        echo " 3. Create Physical Volume"
                        echo ""
                        echo " 4. Extend Volume Group"
                        echo ""
                        echo " 5. Extend Logical Volume"
                        echo ""
			echo " 6. Exit"
                        echo ""
                        read -p 'Enter the action number which you want to perform: ' ACTION
     case $ACTION in
                        1)
 			echo ""
                        lvmdisplay
                        exit;;
                        2)
			showdisks
                        exit;;
                        3)
			pvcreate
                        exit;;
                        4)
			vgextend
                        exit;;
                        5)
			lvextend
                        exit;;
                        6)
                        exit;;
                        *)
                        echo "${ACTION} is not a valid option"
                        echo "Press [enter] key to continue ..."
                        read enterKey
                        ;;
                esac
done
