DIALOG=${DIALOG=dialog}
#set -x
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

function main_(){

$DIALOG --backtitle "WCGVA Welcome Menu" \
	--title "WCGVA Menu" --clear \
        --menu "Choose your Option Here:  " 15 60 8 \
        0 "Show IP Address  	[Show Current IPv4]"\
        1 "Add Routes       	[Add ipv4 routes]" \
        2 "Delete Routes    	[Delete ipv4 routes]" \
        3 "Add ipv6 stack   	[Add an ipv6 address]" \
        4 "RePatch WCG      	[Repatch with hotfixes]" \
        5 "Health Check Status  [Make a Healch Check Status]"  \
	6 "Direct Speed Test  	[Test VM Speed Test]"  \
	7 "Tweak Project	[PAC Perf Users]"\
	8 "Uninstall WCGVA  	[Uninstall WCG and WWS software]" \
        9 "Exit Console     	[Goodbye this menu]"  2> $tempfile

retval=$?

choice=`cat $tempfile`
case $choice in
  0)
    $DIALOG --textbox /etc/sysconfig/network-scripts/ifcfg-eth0 22 70
    main_; 
    ;;
  1)

  $DIALOG --title "Adding Route Confirmation" --yesno "Do you want to add an ipv4 route?" 22 20 ;
    if [ $? == "0" ]
     then
     sh addroutes.sh
    fi
    main_;
    ;;
 2)
  $DIALOG --title "Delete Route Confirmation" --yesno "Do you want to delete an ipv4 route?" 22 20 ;
    if [ $? == "0" ]
     then
     sh delroutes.sh
    fi
    main_;
    ;;

 3)
   $DIALOG --title "Ipv6 Stack" --yesno "Do you want to add an IPV6 address?" 22 20 ;
    if [ $? == "0" ]
     then
     sh ipv6d.sh 
    fi
    main_;
    ;;

















  4)
    $DIALOG --title "Patching Confirmation" --yesno "Do you want to patch the WCG?" 22 20 ;
    if [ $? == "0" ]
     then
     sh patching.sh
    fi
    main_;
    ;;
	
  5) 
   $DIALOG --title "Health Check Confirmation" --yesno "Do you want to exit this menu?" 10 30 ;

    if [ $? == "0" ]
     then
     rm -f StackCheck.txt	
     sh HealthCheck.sh > StackCheck.txt     
	$DIALOG --textbox StackCheck.txt 22 70
     exit
    fi
    main_;
    ;;
	
  6)
   $DIALOG --title "VM Internet Speed" --yesno "Do you want to test VM Internet Speed?" 10 30 ;

    if [ $? == "0" ]
     then
     ./speedtest_cli.py > results.txt &
     sh progress.sh $!
     $DIALOG --textbox results.txt 22 70 		
     rm -f results.txt	
    fi
    main_;
    ;;
  7)
    $DIALOG --title "Tweak Project" --yesno "Do you want to go be an expert?" 22 20 ;
    if [ $? == "0" ]
     then
      python tweaks/tweak.py
    fi
    #main_;
    ;;  

  8)
    $DIALOG --title "UnInstall Confirmation" --yesno "Do you want to uninstall?" 22 20 ;
    if [ $? == "0" ]
     then
     sh UNINSTALLALL.sh
    fi
    main_;
    ;;      
9)
   $DIALOG --title "Exit Menu Confirmation" --yesno "Do you want to exit this menu?" 10 30 ;

    if [ $? == "0" ]
     then
     clear
     exit
    fi
    main_;
    ;;
  255)
    echo "ESC pressed.";;
esac
}

main_
