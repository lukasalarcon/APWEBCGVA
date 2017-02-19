#!/bin/bash
set -x

function AddStackIpv6(){

 cp /etc/sysconfig/network-scripts/ifcfg-eth0 /root/backups
 cp /etc/sysconfig/network-scripts/ifcfg-eth1 /root/backups

if [ "$1"="eth0" ]
 then
 echo "IPV6INIT=yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0;
  echo "IPV6_AUTOCONF=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0;
   echo "IPV6ADDR=$digit/$ipv6mask" >> /etc/sysconfig/network-scripts/ifcfg-eth0;
  echo "IPV6_DEFAULTGW=$ipv6gw/ipv6gwmask" >> /etc/sysconfig/network-scripts/ifcfg-eth0;
 echo "DNS1=$ipv6dns" >> /etc/sysconfig/network-scripts/ifcfg-eth0;
else
  echo "IPV6INIT=yes" >> /etc/sysconfig/network-scripts/ifcfg-eth1;
  echo "IPV6_AUTOCONF=no" >> /etc/sysconfig/network-scripts/ifcfg-eth1;
   echo "IPV6ADDR=$digit/$ipv6mask" >> /etc/sysconfig/network-scripts/ifcfg-eth1;
  echo "IPV6_DEFAULTGW=$ipv6gw/ipv6gwmask" >> /etc/sysconfig/network-scripts/ifcfg-eth1;
 echo "DNS1=$ipv6dns" >> /etc/sysconfig/network-scripts/ifcfg-eth1;
fi
}

function Validateipv6(){

  
  INPUT=""
  IsTrue="1"
  O=""
  INPUT=$1

  while [ "$O" != "$INPUT" ]; do
   O="$INPUT"

   # fill all words with zeroes

    INPUT="$( sed  's|:\([0-9a-f]\{3\}\):|:0\1:|g' <<< "$INPUT" )"
    INPUT="$( sed  's|:\([0-9a-f]\{3\}\)$|:0\1|g'  <<< "$INPUT")"
    INPUT="$( sed  's|^\([0-9a-f]\{3\}\):|0\1:|g'  <<< "$INPUT" )"

    INPUT="$( sed  's|:\([0-9a-f]\{2\}\):|:00\1:|g' <<< "$INPUT")"
    INPUT="$( sed  's|:\([0-9a-f]\{2\}\)$|:00\1|g'  <<< "$INPUT")"
    INPUT="$( sed  's|^\([0-9a-f]\{2\}\):|00\1:|g'  <<< "$INPUT")"

    INPUT="$( sed  's|:\([0-9a-f]\):|:000\1:|g'  <<< "$INPUT")"
    INPUT="$( sed  's|:\([0-9a-f]\)$|:000\1|g'   <<< "$INPUT")"
    INPUT="$( sed  's|^\([0-9a-f]\):|000\1:|g'   <<< "$INPUT")"

done

# now expand the ::
GRPS="0"
MISSING=""
ZEROES=""
grep -qs "::" <<< "$INPUT"
if [ "$?" -eq 0 ]; then
  GRPS="$(sed  's|[0-9a-f]||g' <<< "$INPUT" | wc -m)"
  echo "CARR $GRPS"
  ((GRPS--)) # carriage return
  ((MISSING=8-GRPS))
  for ((i=0;i<$MISSING;i++)); do
	  ZEROES="$ZEROES:0000"
	  done

# be careful where to place the :
 INPUT="$( sed  's|\(.\)::\(.\)|\1'$ZEROES':\2|g'   <<< "$INPUT")"
 INPUT="$( sed  's|\(.\)::$|\1'$ZEROES':0000|g'   <<< "$INPUT")"
 INPUT="$( sed  's|^::\(.\)|'$ZEROES':0000:\1|g;s|^:||g'   <<< "$INPUT")"

fi

# an expanded address has 39 chars + CR
if [ $(echo $INPUT | wc -m) != 40 ]; then
 #echo "invalid IPv6 Address"
 IsTrue="0"; 
fi


}

 echo "Please, enter your IPv6 address:";
  echo "Example: 2001:0000:0000:0000:0000:0000:0000:0000";

    digit="";
    ac=0;
    IsTrue=0;
    echo $IsTrue;
    while [ "$ac" == "0" ];
    do
     IsTrue=0;
       while [ "$IsTrue" == "0" ]
        do
         echo "Try your IPv6 Address:";
         read digit;
         Validateipv6 $digit;
       done

       digit=$INPUT;
       IsTrue=0; 

       echo "Please, enter your Ipv6 Mask: (48, 64, etc)";
       read ipv6mask;

 
       while [ "$IsTrue" == "0" ]
        do
         echo "Try your IPv6 Default Gateway";
         read ipv6gw;
         Validateipv6 $ipv6gw;
       done

       ipv6gw=$INPUT;
       IsTrue=0;

       echo "Please, enter your IPv6 Gateway Mask:";
       read ipv6gwmask;

      while [ "$IsTrue" == "0" ]
        do
        
        echo "Please, enter your IPv6 DNS:";
         read ipv6dns;
         Validateipv6 $ipv6dns;
       done

             
       ipv6dns=$INPUT;
       IsTrue=0;



       
      echo "Please, enter what interface will support ipv6";
      echo "1) eth0";
      echo "2) eth1";

      while [ "$intf" != "1" ] && [ "$intf" != "2"  ]
        do
       echo "Please, enter what interface will support ipv6";
        echo "1) eth0";
        echo "2) eth1";
       read intf;
       done


      ac=1;
       
       echo "Main Ipv6 address: $digit/$ipv6mask";
       echo "Ipv6 Gateway: $ipv6gw/$ipv6gwmask";
       echo "Ipv6 DNS: $ipv6dns";
       if [ "$intf" == "1" ];
        then
        echo "Interface: eth0";
       else
        echo "Interface: eth1";
       fi
       echo " Are you satisfied with this settings?(y/n)";
    read yn;

   if [ "$yn" != "y" ]  
    then    

    ac=0;

   fi



 done

