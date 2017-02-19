#!/bin/bash
#set -x
_ECHO="/bin/echo -e"
_CP="/bin/cp"
_SED="/bin/sed"
SHOME="/home/admin"
MYETH0="/etc/sysconfig/network-scripts/ifcfg-eth0"
MYETH1="/etc/sysconfig/network-scripts/ifcfg-eth1"

##########   ENABLE IPV6 ##################
${_ECHO} "Enabling ipv6 in sysctl\n"


cp /etc/sysctl.conf $SHOME/backups
 
sed --in-place '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
sed --in-place '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf

echo -e "net.ipv6.conf.all.disable_ipv6 = 0" >> /etc/sysctl.conf
echo -e "net.ipv6.conf.default.disable_ipv6 = 0" >> /etc/sysctl.conf


${_ECHO} "Enabling IPv6 in modprobe.d\n"

if [ -f /etc/modprobe.d/disable-ipv6.conf ] 
 then
  	cp /etc/modprobe.d/disable-ipv6.conf $SHOME/backups
	rm -f /etc/modprobe.d/disable-ipv6.conf

fi 


${_ECHO} "Adding entries to network file for enabling"

cp /etc/sysconfig/network $SHOME/backups

${_SED} -i "s/NETWORKING_IPV6=.*/NETWORKING_IPV6=yes/" /etc/sysconfig/network

${_SED} -i "s/IPV6INIT=no/IPV6INIT=yes/" /etc/sysconfig/network

#######
# ENABLE OVER ETH0

cp $MYETH0 $SHOME/backups

${_SED} -i "s/IPV6INIT=no/IPV6INIT=yes/" $MYETH0 

######
# ENABLE OVER ETH1

cp $MYEHT1 $SHOME/backups


if [ -f $MYETH1 ]
then
${_SED} -i "s/IPV6INIT=no/IPV6INIT=yes/" $MYETH1
fi


service network restart

${_ECHO} "Please, reboot your VM to apply changes"


############ IPV6 ENABLE ############
