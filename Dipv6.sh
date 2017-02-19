#!/bin/bash

_ECHO="/bin/echo -e"
_CP="/bin/cp"
_SED="/bin/sed"
SHOME="/home/admin"
MYETH0="/etc/sysconfig/network-scripts/ifcfg-eth0"
MYETH1="/etc/sysconfig/network-scripts/ifcfg-eth1"

##########   DISABLE IPV6 ##################
${_ECHO} "disabling ipv6 in sysctl.conf\n"

cp /etc/sysctl.conf $SHOME/backups 
cp /etc/sysconfig/network $SHOME/backups 



if grep -Fxq "net.ipv6.conf.all.disable_ipv6" /etc/sysctl.conf 
then
${_SED} -i "s/net.ipv6.conf.all.disable_ipv6 =.*/net.ipv6.conf.all.disable_ipv6 = 1/" /etc/sysctl.conf
else
${_ECHO} -e "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
fi



if grep -Fxq "net.ipv6.conf.default.disable_ipv6" /etc/sysctl.conf
then
  ${_SED} -i "s/net.ipv6.conf.default.disable_ipv6 =.*/net.ipv6.conf.default.disable_ipv6 = 1/" /etc/sysctl.conf

else
 ${_ECHO} -e "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
fi



${_ECHO} "Disabling IPv6 in modprobe.d\n"
${_ECHO} "options ipv6 disable=1" >> /etc/modprobe.d/disable-ipv6.conf

${_ECHO} "Adding entries to network file"

######
# DISABLE OVER ETH1

cp $MYEHT1 $SHOME/backups
cp $MYETH0 $SHOME/backups


if [ -f $MYETH1 ]
then
${_SED} -i "s/IPV6INIT=yes/IPV6INIT=no/" $MYETH1
fi

######
# DISABLE OVER ETH0


if [ -f $MYETH0 ]
then
${_SED} -i "s/IPV6INIT=no/IPV6INIT=yes/" $MYETH0
fi






#DISABLE OVER NETWORK FILE

${_SED} -i "s/IPV6INIT=.*/IPV6INIT=no/" /etc/sysconfig/network









service network restart

${_ECHO} "Please, reboot your VM to apply changes\n"

############ IPV6 Disable complete ############
