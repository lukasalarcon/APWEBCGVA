	#!/bin/bash
	#set -x

	SHOME="/home/admin"


	removeWWS ()
	{
        if [ -f /opt/Websense/bin/websense.ini ]
         then
	  wwshomeu=$SHOME/scripts
	   echo ""
	    echo "Launching the un-installer..."
	   echo ""
	  cd $wwshomeu
	  ./wws_uninstall.sh
          rm -fR /opt/Websense
        fi
        
	}

	removeWCG ()
	{

	wcghomeu=/home/admin/scripts
	# mkdir $wcghomeu
	cd $wcghomeu
	./wcg_uninstall.sh

	if [ -f /opt/WCG/websense.ini ]
	then
	    echo "Check:::WCG already installed"
	else
	    echo It seems to be already uninstalled    
	     echo 0 > $wcghomeu/.ready.txt		 
	fi

	}

	uninstallCron ()
	{

	crontab -l > file;
	#sed  
	#eliminar via sed!!!
        sed -i '/clean_cache.sh/d' file
        crontab file
        rm -f file 


	}

	uninstallNTP()
        {

	service ntpd stop
        rm -f /etc/ntp.conf
        cp $SHOME/backups/ntp.conf /etc/ntp.conf 


        }

	uninstallIptables()
        {
          	iptables -F
		iptables -X
		iptables -t nat -F
		iptables -t nat -X
		iptables -t mangle -F
		iptables -t mangle -X
		iptables -P INPUT ACCEPT
		iptables -P FORWARD ACCEPT
		iptables -P OUTPUT ACCEPT

          /etc/init.d/iptables stop
          chkconfig iptables off
          rm -f /etc/sysconfig/iptables

        }



main ()
{
clear
echo ""
figlet APWEBCGVA 

echo ""

   
ready=`head -1 .ready.txt`

if [ $ready =  "0" ]; then
    echo "Nothing to do..."
    exit 0    
fi

echo ""




        cp /etc/hosts $SHOME/backups
        cp /etc/resolv.conf $SHOME/backups
        cp /etc/sysconfig/network $SHOME/backups
        cp /etc/sysconfig/network-scripts/ifcfg-eth0 $SHOME/backups
	cp /etc/ntp.conf $SHOME/backups
        if [ -f /etc/sysconfig/network-scripts/route-eth0 ]
        then
         cp /etc/sysconfig/network-scripts/route-eth0 $SHOME/backups
         rm -f /etc/sysconfig/network-scripts/route-eth0
        fi
        if [ -f /etc/sysconfig/network-scripts/route-eth1 ]
        then
         cp /etc/sysconfig/network-scripts/route-eth1 $SHOME/backups
         rm -f /etc/sysconfig/network-scripts/route-eth1
	fi
	#REMUEVO ENTRADA POR FREEZE EN INSTALACION Y LUEGO DEJO IGUAL	
	sed -i "s/\.\/themenu.sh/#\.\/themenu.sh/" $SHOME/scripts/Sup14.sh			



	removeWWS
	removeWCG
	uninstallCron
        uninstallNTP	
        uninstallIptables
 	#/root/scripts/./
	echo "Uninstalling process DONE"
	rm -fR /opt/WWSInstaller
	rm -fR /opt/WCGInstaller
	rm -fR /opt/Websense
        rm -f /root/Websense_InstallLog.log
        rm -fR /opt/WSGUP



        rm -fR /root/WCG
	rm -fR /opt/Websense
        rm -f .ready.txt
        #rm -f /etc/ntp.conf
        echo 0 > .ready.txt
}

# Start of the program
main


