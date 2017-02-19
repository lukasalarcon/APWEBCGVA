#!/bin/bash
#set -x

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
GRPS=""
MISSING=""
ZEROES=""
grep -qs "::" <<< "$INPUT"
if [ "$?" -eq 0 ]; then
  GRPS="$(sed  's|[0-9a-f]||g' <<< "$INPUT" | wc -m)"
  #echo "CARR $GRPS"
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

#dialog --inputbox "Please, enter your IPv6 address: " 8 40 2 
#echo "Example: 2001:0000:0000:0000:0000:0000:0000:0000";

    digit="";
    ac=0;
    IsTrue=0;
    echo $IsTrue;
    while [ "$ac" == "0" ];
    do
     IsTrue=0;
       while [ "$IsTrue" == "0" ]
        do
         dialog --inputbox "Please, enter your IPv6 address: " 8 40 2>dialog.txt
         d=$?;
         digit=$(<dialog.txt);
         dialog --title "IP version 6" --msgbox "$digit" 10 41
         Validateipv6 $digit;
         rm -f dialog.txt
       done

       digit=$INPUT;
       IsTrue=0; 

       dialog --inputbox "Please, enter your Ipv6 Mask: (48, 64, etc)" 8 40 2>dialog.txt
       ipv6mask=$(<dialog.txt);
       rm -f dialog.txt
  
       while [ "$IsTrue" == "0" ]
        do
         dialog --inputbox "Try your IPv6 Default Gateway" 8 40 2>dialog.txt
         ipv6gw=$(<dialog.txt);
         Validateipv6 $ipv6gw;
         rm -f dialog.txt   
       done

       ipv6gw=$INPUT;
       IsTrue=0;

       dialog --inputbox "Please, enter your IPv6 Gateway Mask:(48, 64, etc)" 8 40 2>dialog.txt 
       ipv6gwmask=$(<dialog.txt);
       rm -f dialog.txt 
      while [ "$IsTrue" == "0" ]
        do
        
        dialog --inputbox "Please, enter your IPv6 DNS:" 8 40 2>dialog.txt
         ipv6dns=$(<dialog.txt);
          #Validateipv6 $ipv6dns;
          rm -f dialog.txt;
         IsTrue="1";
       done

             
       ipv6dns=$INPUT;
       IsTrue=0;
       intf="3" 

      while [ "$intf" != "1" ] && [ "$intf" != "2"  ]
        do

      dialog --radiolist "Please, enter what interface will support ipv6:" 10 40 4 1 eth0 on 2 eth1 off>dialog.txt 
       intf=$(<dialog.txt)
        rm -f dialog.txt;

       done

      ac=1;
       
       
       echo "Main Ipv6 address: $digit/$ipv6mask">values.txt 
       echo "Ipv6 Gateway: $ipv6gw/$ipv6gwmask">>values.txt 
       echo "Ipv6 DNS: $ipv6dns">>values.txt

       if [ "$intf" == "1" ];
        then
        echo "Interface: eth0">>values.txt;
       else
        echo "Interface: eth1">>values.txt;
       fi
       
       dialog --title "Settings" --backtitle "Your current settings" --clear --textbox values.txt 20 71  
       rm -f values.txt;

       dialog --title "Confirm"  --yesno "Are you satisfied with this settings?(y/n)" 10 25 2>dialog.txt;
    yn=$(<dialog.txt);
   rm -f dialog.txt;
   if [ "$yn" != "y" ]  
    then    

    ac=0;

   fi

 done

