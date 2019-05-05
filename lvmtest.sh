#!/bin/bash

# Declaring variable

USER_NAME=$(id -un)
HOST_FILE="${HOME}/lvmhosts.txt"
DATE=$(date +%Y-%m-%d)


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
                        echo '1'
                        exit;;
                        2)
			echo '2'
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
