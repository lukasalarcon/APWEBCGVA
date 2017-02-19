#!/bin/bash
#set -x
host=`hostname`
pid=$$
yn="y"
yesno="n"
myhome="/home/admin/scripts"
cd $myhome

while [ "$yn" == "y" ] || [ "$yn" == "Y" ]
do

 while [ "$yesno" == "n" ] || [ "$yesno" == "N" ]
  do
   echo "Please, enter your route in the following format: 192.0.0.0/24"
    read theroute
    echo ""
    echo "Please, enter the IP address for the gateway for the previous route:"
    read thegw
   echo ""
   echo "Please,enter the Interface who will command that route:eth0 or eth1:"
    echo -e "1) eth0"
    echo -e "2) eth1"
   read mydev
   echo "You have enter:"
   echo "Route: $theroute"
   echo "Gateway: $thegw"
   if [ "$mydev" == "1" ];
     then 
	mydev="eth0"
     else
	mydev="eth1"
   fi
 	
   echo "Network Interface: $mydev"
    echo ""
    echo "Are you satisfied with this settings: y/n"
   read yesno
 done

Rt="$theroute via $thegw dev $mydev"

var1=$(echo $theroute | cut -f1 -d/)

if [ "$mydev" == "eth0" ]
 then
  RtFile="/etc/sysconfig/network-scripts/route-eth0"
 else
  RtFile="/etc/sysconfig/network-scripts/route-eth1"
fi

>/tmp/rt-entry.$pid
>/tmp/fileentry.$pid

echo -e "Check:::Checking for Static route File..."
 if [ -f $RtFile ]; then
   echo -e "Static route file exists."
    echo -e "Check:::Checking if route entry already Exists"
     var2=$(more $RtFile|grep $var1|awk '{print $1}')
   if [ $var2 ] ; then
    echo -e "Below entry already exist.."
     echo
      echo ".==============================================================."
      cat /tmp/fileentry.$pid
     echo ".==============================================================."
    echo
   else
    echo -e "File had no entry for the new route...Adding entry.."
     echo -e $Rt >> /etc/sysconfig/network-scripts/route-$mydev
    echo
   fi
	
   echo -e "Check:::Checking if the route entry already enabled.."

   if [ `/bin/netstat -rn|grep $var1 1> /tmp/rt-entry.$pid` ] ; then
   echo -e "$host:::Static route already enabled.. exiting"
    echo
     echo ".==============================================================."
     cat /tmp/rt-entry.$pid
     echo ".==============================================================."
    echo
   exit 1
   fi
  echo -e "Route not enabled"
  echo
 else
  echo -e "Static route file Doesn.t exist , Creating New one..."
   echo -e $Rt >> /etc/sysconfig/network-scripts/route-$mydev
  echo
fi

echo
echo -e "Action:::Enabling new Routes on interface $mydev"

	ifdown $mydev
	ifup $mydev

echo -e "Check:::checking for the new Route added ...."
kroute=$(/bin/netstat -rn|grep $var1| awk '{print $1}')
 if [ "$kroute" == "$var1"  ]; then
  echo -e "$var1 ::: New route added successfully."
  cat /tmp/rt-entry.$pid
  else
   echo -e "$host ::: Error: Route add failed, check manually."
   echo
 fi
echo -e "Would you like to add another route or delete the route:"
echo -e "1) Add another route"
echo -e "2) Delete a route"
echo -e "3) Exit"
read yn

if [ "$yn" == "3" ];then
  exit 1 
fi

if [ "$yn" == "2" ];then
 $myhome/./delroutes.sh
fi

if [ "$yn" == "1" ];then
 yn="y" 
fi

 
done
