#!/bin/bash

# Declaring variable

USER_NAME=$(id -un)
HOST_FILE="${HOME}/lvmhosts.txt"
DATE=$(date +%Y-%m-%d)
SSH_LOGIN=$(ssh -q -o ConnectTimeout=30 -o 'StrictHostKeyChecking no')

# Fucntion for displaying the current pv's lv's and vg's

function lvmdisplay()
{
for ip in $(cat "${HOST_FILE}")
 do
   ssh -q -o ConnectTimeout=30 -o 'StrictHostKeyChecking no' -T "${USER_NAME}"@"${ip}" ip="${ip}"  'bash -s' << 'ENDSSH'
   echo ""
   echo  "Displaying the current pv's lv's and vg's - ${ip}"
   echo "=========================================================";echo ""
   sudo pvs ; echo "=============================================" ; sudo lvs ; echo "============================================="  ; sudo vgs ; echo "============================================="; echo ""
   sudo pvdisplay ; echo "=======================" ; sudo lvdisplay ; echo "============================="  ; sudo vgdisplay ; echo "=============================" 
ENDSSH
done
}

# Function for displaying the available free disks to create PV's

function showdisks()
{
for ip in $(cat "${HOST_FILE}")
 do
     ssh -q -o ConnectTimeout=30 -o 'StrictHostKeyChecking no' -T "${USER_NAME}"@"${ip}" ip="${ip}"  'bash -s' << 'ENDSSH'
     echo ""; echo "NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT - Server - ${ip}"; echo "================================================================";
     SHOW_DISKS=$(sudo /usr/bin/lsblk | sed 1d | grep "disk" | awk -F " " '{print $1}')
     for i in $(echo "${SHOW_DISKS}" | tr ' ' '\n')
      do
          sudo /usr/sbin/pvdisplay /dev/"${i}" > /dev/null 2>&1
           RESULT1=$(echo ${?})
             if [[ "${RESULT1}" != "0" ]]
                then
                  sudo /usr/bin/df -hT | grep -i "/dev/${i}" > /dev/null 2>&1
                  RESULT2=$(echo ${?})
                    if [[ "${RESULT2}" != "0" ]]
                       then
                          DISK_FOUND=$(sudo /usr/bin/lsblk /dev/${i} | sed 1d)
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
done
}


# Testing User Privilege 

if [[ "${USER_NAME}" = "root" ]]; 
then
   echo "Run the command with a non-root User"
   exit 1
fi


if [[ ! -f "${HOST_FILE}" ]];
then
   echo "Hostlist file does not exists. Create file ${HOST_FILE} in the ${USER_NAME} home directory with the list of servers"
   exit 1
else
   if [[ -s "${HOST_FILE}" ]];
   then 
      echo "${HOST_FILE} file not Empty" > /dev/null 2>&1
   else
      echo "${HOST_FILE} should not be Empty. Add the hostname to perform the task in the ${HOST_FILE}"
      exit 1
fi
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
                        echo " 4. Create Volume Group"
                        echo ""
                        echo " 5. Create Logical Volume"
                        echo ""
                        echo " 6. Create Filesystem"
                        echo ""
                        echo " 7. Extend Existing Filesystem"
                        echo ""
                        echo " 8. Mount Filesystem"
                        echo ""
			echo " 9. Exit"
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
			echo '3'
                        exit;;
                        4)
			echo '4'
                        exit;;
                        5)
			echo '5'
                        exit;;
                        6)
			echo '6'
                        exit;;
                        7)
                        echo '7'
                        exit;;
                        8)
                        echo '8'
                        exit;;
                        9)
                        exit;;
                        *)
                        echo "${ACTION} is not a valid option"
                        echo "Press [enter] key to continue ..."
                        read enterKey
                        ;;
                esac
done
