################################
# iptables config example script
################################
# This script enables iptables, FLUSHES THE CURRENT SETTINGS, and then 
# loads settings that are consistent with recommendations in the 
# Websense Content Gateway Installation Guide.
#
# Please have access to the console in case you "lock yourself out".
#
# This script requires that you identify the ethernet interfaces used
# for the following roles:
#
# MGMT_NIC   - This is the physical interface used by the system
#              administrator to manage the computer.
#
# WAN_NIC    - This is the physical interface used to request pages 
#              from the Internet (usually most secure).
#
# CLIENT_NIC - This is the physical interface used by the clients to
#              request data from the proxy
#
# CLUSTER_NIC- This is the physical interface used by the proxy to 
#              communicate for clustering
#
# This script defaults to all interfaces being eth0 - where the
# gateway has a single NIC and resides on an internal network.
#
#
#
###
# Configuration Parameters
###
# Find the install directory
WHERE=`head -1 /etc/content_gateway 2>/dev/null`
# Peek into the config file for the Policy Server IP Address
POLICY_SERVER_IP=`/bin/grep PolicyServerIP ${WHERE}/websense.ini | grep -v "^#" | head -1 | awk -F = '{print $2}'`
#
# Peek into the config file for the Filtering Service IP Address
FILTERING_SERVICE_IP=`/bin/grep wtg.config.wse_server_ip ${WHERE}/config/records.config  | grep -v "^#" | head -1 | awk '{print $4}'`
#
# Peek into the config file for the clustering multicast group address
CLUSTER_MCAST_ADDRESS=`/bin/grep proxy.config.cluster.mc_group_addr  ${WHERE}/config/records.config  | grep -v "^#" | head -1 | awk '{print $4}'`


# Interface to accept connections to the Web Management GUI
MGMT_NIC="eth0"
# Interface to initiate connections to the internet for content
WAN_NIC="eth0"
#Interface to accept connections from users
CLIENT_NIC="eth0" 
#Interface to share clustering information
CLUSTER_NIC="eth1" 

YN="n"


while [ "$YN" == "N" ] || [ "$YN" == "n" ]
do

echo "Please, enter Management Interface:(choose 1 or 2)"
echo "1 - eth0"
echo "2 - eth1"
read M
if [ "$M" == "2" ]; then
   MGMT_NIC="eth1"
fi
echo ""
echo "if you dont have a WAN interface, use eth0"
echo "Please, enter WAN Interface:(choose 1 or 2)"
echo "1 - eth0"
echo "2 - eth1"
read W
if [ "$W" == "2" ]; then
   WAN_NIC="eth1"
fi

echo ""
echo "Please, enter Client Interface:(choose 1 or 2)"
echo "1 - eth0"
echo "2 - eth1"
read C
if [ "$C" == "2" ]; then
   CLIENT_NIC="eth1"
fi

echo ""
echo "If you dont set Cluster, please choose eth0"
echo "Please, enter Cluster Interface:(choose 1 or 2)"
echo "1 - eth0"
echo "2 - eth1"
read CL
if [ "$CL" == "1" ]; then
   CLUSTER_NIC="eth0"
fi

echo ""
#
# Echo the configuration, even if we don't ask to confirm.
###
echo "Configuring iptables for the following:"
echo "Policy Server IP: $POLICY_SERVER_IP"
echo "Internet facing NIC: $WAN_NIC"
echo "Management facing NIC: $MGMT_NIC"
echo "Client facing NIC: $CLIENT_NIC" 
echo "Cluster NIC: $CLUSTER_NIC" 

echo "Are you satisfied with this settings? [y/n]:"
read YN

done


###
# Enable iptables service.
###
# enable iptables service now
/sbin/service iptables start
# enable iptables on restart
/sbin/chkconfig iptables on 

###
# iptables configuration
###

# !!!FLUSH THE EXISTING IPTABLES CONFIG!!!
/sbin/iptables --flush
#
# The following rule should be first. - Applied to ALL interfaces
/sbin/iptables --policy INPUT DROP
# Important for general system security - Applied to ALL interfaces
/sbin/iptables --policy OUTPUT ACCEPT
/sbin/iptables --policy FORWARD DROP 
/sbin/iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 

###
# Protocols for Device Management and Basic Operation
###
#Internal and Loopback Communication
#
#Don't do connection tracking for local connections
/sbin/iptables -I OUTPUT -o lo -t raw -j NOTRACK
#
/sbin/iptables -I INPUT -i lo -j ACCEPT
/sbin/iptables -I INPUT -i internal -j ACCEPT
#SSH
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport   22 -j ACCEPT
#ICMP - ping
/sbin/iptables -i $MGMT_NIC -I INPUT -p ICMP -j ACCEPT
#Websense Managment Interface Proxy
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 8071 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 8081 -j ACCEPT
#Websense Management Interface and Filtering Service Components
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 15868 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 15869 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 55807 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 55871 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 55808 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 55827 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 9447 -j ACCEPT
###
# Proxy Ports for Either Explicit or Transparent Proxy Deployment
###
#Explicit  proxy of http 
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport 8080 -j ACCEPT
#Explicit proxy of https 
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport 8070 -j ACCEPT
#Explicit  proxy of ftp 
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport 2121 -j ACCEPT 

###
# Additional Protocols Ports for Transparent Proxy Deployment
###
#Transparent proxy of http 
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport   80 -j ACCEPT
#Transparent proxy of https
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport  443 -j ACCEPT
#Transparent proxy of ftp
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport   21 -j ACCEPT
#Transparent proxy of dns (A-Record Requests Only)
/sbin/iptables -i $CLIENT_NIC -I INPUT -p udp --dport   53 -j ACCEPT
/sbin/iptables -i $CLIENT_NIC -I INPUT -p udp --dport 5353 -j ACCEPT
# WCCP Protocol Communication with Router/Switch
/sbin/iptables -i $CLIENT_NIC -I INPUT -p udp --dport 2048 -j ACCEPT 
#SOCKS proxy
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport   1080 -j ACCEPT


###
# Data Security Policy Engine (on-box) - DEFAULT ON 
###
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 5820 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 8880 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 8889 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 8888 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 9080 -j ACCEPT

###
# Proxy Clustering - DEFAULT ON 
###
# For configuration communications
/sbin/iptables -i $CLUSTER_NIC -I INPUT -p tcp --dport 8086 -j ACCEPT
/sbin/iptables -i $CLUSTER_NIC -I INPUT -p udp --dport 8086 -j ACCEPT
/sbin/iptables -i $CLUSTER_NIC -I INPUT -p tcp --dport 8087 -j ACCEPT
/sbin/iptables -i $CLUSTER_NIC -I INPUT -p udp --dport 8088 -j ACCEPT
/sbin/iptables -i $CLUSTER_NIC -I INPUT -p udp -d $CLUSTER_MCAST_ADDRESS/32 -j ACCEPT

###
# MISC Proxy Feature Ports - DEFAULT ON -  Uncomment only if required
###
# For statistic gathering using overseer port
/sbin/iptables -i   $MGMT_NIC -I INPUT -p tcp --dport 8082 -j ACCEPT
# If the proxy hosts a PAC file (Browser Auto-Config)
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport 8083 -j ACCEPT
# Log collation for multiple proxies
/sbin/iptables -i   $MGMT_NIC -I INPUT -p tcp --dport 8085 -j ACCEPT
# SNMP Access
/sbin/iptables -i   $MGMT_NIC -I INPUT -p udp --dport 8089 -j ACCEPT
# Cache hierarchy ICP protocol communications
/sbin/iptables -i   $MGMT_NIC -I INPUT -p udp --dport 3130 -j ACCEPT 
# Add support for SSH
/sbin/iptables -i   $MGMT_NIC -I INPUT -p udp --dport 22 -j ACCEPT
# Add support for WebMin Interface
/sbin/iptables -i   $MGMT_NIC -I INPUT -p tcp --dport 9447 -j ACCEPT
 

 
###
#Remote Policy Server - DEFAULT ON 
###
#Include this rule in your IPTables firewall if the Websense Policy Server
#does not run on the Content Gateway machine.  This is required because
#Websense Content Gateway has bidirectional communication over ephemeral
#ports.
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp -s $POLICY_SERVER_IP --dport 1024:65535 -j ACCEPT 
 
###
#Local  Policy Server - DEFAULT ON 
###
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 40000 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 55806 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 55880 -j ACCEPT
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp --dport 55905 -j ACCEPT

###
#Remote Filtering Service - DEFAULT ON 
###
#Include this rule in your IPTables firewall if the Websense Filtering Service
#does not run on the Content Gateway machine.  This is required because
#Websense Content Gateway has bidirectional communication over ephemeral
#ports.
/sbin/iptables -i $MGMT_NIC -I INPUT -p tcp -s $FILTERING_SERVICE_IP --dport 1024:65535 -j ACCEPT 

###
#Local  Filtering Service - DEFAULT ON 
###
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport 15868 -j ACCEPT
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport 15869 -j ACCEPT
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport 55807 -j ACCEPT
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport 55871 -j ACCEPT
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport 55808 -j ACCEPT
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport 55827 -j ACCEPT


###
# Explicit Proxy Only - PAC file distribution without ARM enabled. - DEFAULT OFF
###
#Browsers will request PAC file from  proxy using http 80
/sbin/iptables -i $CLIENT_NIC -I INPUT -p tcp --dport   80 -j ACCEPT
#Redirect port 80 traffic to PAC file port 8083
/sbin/iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 80 -j REDIRECT --to-ports 8083


####
# BROKER
####





###
# Save iptables configuration for next reboot
###
/sbin/iptables-save > /etc/sysconfig/iptables
# Echo configuration to user
/sbin/iptables-save  

###
# End of script 
###
