#!/bin/bash
#set -x
yn="y"
yesno="n"

while [ "$yn" == "y" ] || [ "$yn" == "Y" ]
do

 while [ "$yesno" == "n" ] || [ "$yesno" == "N" ]
  do
   echo "Please, enter the Interface that command that route: [eth0] or [eth1]:"
   echo "1) eth0"
   echo "2) eth1"	 
   read mydev
   if [ "$mydev" == "1" ]; then
     mydev="eth0"
    else
     mydev="eth1"
   fi
   echo "You have enter:"
   echo "Network Interface: $mydev"
   echo ""
   echo "Are you satisfied with this settings: y/n"
   read yesno
 done


 if [ "$mydev" == "eth0" ]
  then
   RtFile="/etc/sysconfig/network-scripts/route-eth0"
  else
  RtFile="/etc/sysconfig/network-scripts/route-eth1"
 fi
 clear
 a=0
 while read line; do
 a=$(($a+1))
 echo "$a ) $line" 
 done < $RtFile ; 
 
 echo -e "Please, choose the route that you want to remove:"
 read opcion

 if [ $opcion -gt $a ]
  then
    echo -e "We cannot find the option.Please, try again"
  else
      sed -i ${opcion}d $RtFile
      echo "Route [REMOVED]" 
 fi
 echo -e "Action:::Disabling and Enabling  Routes on interface $mydev"
	ifdown $mydev
	ifup $mydev
 echo "........"
 echo -e "Would you like to: "
 echo -e "1) Delete a route"
 echo -e "2) Add a route"
 echo -e "3) Exit"
 read yn

 case "$yn" in
 
 1) yn="y"
    ;;
 2) ./addroutes.sh
    ;;
 3) exit 0
    ;;
 esac



done
