#!/bin/bash
#set -x
echo "WCG Health Check script - Version 1"
echo

# We want to run this script as root
USER_ACCOUNT=`whoami`
if [ "$USER_ACCOUNT" != "admin" -a "$USER_ACCOUNT" != "root"  ]; then
    echo "This script requires root privileges to execute properly."
    exit
fi

# First identify all the tools this script will use so we may verify their presence
# TODO

# Save off any environment variables this script might change over the course of its execution
# TODO

# List all the tests here.  We'll set them all to failed initially and then update them once the test has completed.
POLICY_SERVER_IP_MATCH_TEST=FAILED.
POLICY_SERVER_PORT_MATCH_TEST=FAILED.
SCATTER_GATHER_OFF_TEST=PASSED. # Special case...
ROUTING_CACHE_OVERFLOW_TEST=FAILED.
ARP_CACHE_OVERFLOW_TEST=FAILED.
DNS_CONNECTIVITY_TEST=PASSED. # Special case...
HOSTNAME_TEST=FAILED.
FILTERING_SERVER_CONNECTIVITY_TEST=FAILED.
POLICY_SERVER_CONNECTIVITY_TEST=FAILED.
GATEWAY_CONNECTIVITY_TEST=FAILED.
DATABASE_DOWNLOAD_SERVER_CONNECTIVITY_TEST=FAILED.
WEBSENSE_DOT_COM_CONNECTIVITY_TEST=FAILED.
CONTENT_GATEWAY_RUNNING_TEST=FAILED.
CONTENT_MANAGER_RUNNING_TEST=FAILED.
MICRODASYS_INBOUND_RUNNING_TEST=FAILED.
MICRODASYS_OUTBOUND_RUNNING_TEST=FAILED.
HTTP_PORT_LISTENING_TEST=FAILED.
HTTPS_PORT_LISTENING_TEST=FAILED.
SEND_HTTP_11_TEST=FAILED.
CHUNKING_DISABLED_TEST=FAILED.
KERNEL_VERSION_TEST=FAILED.
ARM_ENABLED_TEST=FAILED.
ARM_LOADED_TEST=FAILED.
CRASH_FINDING_TEST=FAILED.

# Find the install directory
WCG_INSTALL_DIR=`head -1 /etc/content_gateway 2>/dev/null`
echo "WCG installation directory = $WCG_INSTALL_DIR"
echo

# Peek into the websense.ini file for the Policy Server IP Address
WEBSENSE_INI_POLICY_SERVER_IP=`/bin/grep PolicyServerIP ${WCG_INSTALL_DIR}/websense.ini | grep -v "^#"  | awk -F = '{print $2}'`
echo "Policy Server IP as listed in websense.ini = $WEBSENSE_INI_POLICY_SERVER_IP"
WEBSENSE_INI_POLICY_SERVER_PORT=`/bin/grep PolicyServerPort ${WCG_INSTALL_DIR}/websense.ini | grep -v "^#"  | awk -F = '{print $2}'`
echo "Policy Server Port as listed in websense.ini = $WEBSENSE_INI_POLICY_SERVER_PORT"
echo

# Get the policy server IP from records.config
RECORDS_CONFIG_POLICY_SERVER_IP=`/bin/grep wtg.config.policy_server_ip ${WCG_INSTALL_DIR}/config/records.config  | grep -v "^#" | awk '{print $4}'`
echo "Policy Server IP as listed in records.config = $RECORDS_CONFIG_POLICY_SERVER_IP"
RECORDS_CONFIG_POLICY_SERVER_PORT=`/bin/grep wtg.config.policy_server_port ${WCG_INSTALL_DIR}/config/records.config  | grep -v "^#" | awk '{print $4}'`
echo "Policy Server Port as listed in records.config = $RECORDS_CONFIG_POLICY_SERVER_PORT"
echo

# Make sure the policy server IPs in both websense.ini and records.config match
if [ "$WEBSENSE_INI_POLICY_SERVER_IP" != "$RECORDS_CONFIG_POLICY_SERVER_IP" ]; then
    echo "WARNING!  Policy Server IPs in websense.ini and records.config do NOT match!"
    echo
else
    POLICY_SERVER_IP_MATCH_TEST=PASSED.
fi

# Make sure the policy server ports in both websense.ini and records.config match
if [ "$WEBSENSE_INI_POLICY_SERVER_PORT" != "$RECORDS_CONFIG_POLICY_SERVER_PORT" ]; then
    echo "WARNING!  Policy Server ports in websense.ini and records.config do NOT match!"
    echo
else
    POLICY_SERVER_PORT_MATCH_TEST=PASSED.
fi

# Peek into the config file for the Filtering Service IP Address
FILTERING_SERVICE_IP=`/bin/grep wtg.config.wse_server_ip ${WCG_INSTALL_DIR}/config/records.config  | grep -v "^#" | awk '{print $4}'`
echo "Filtering Service IP = $FILTERING_SERVICE_IP"

FILTERING_SERVICE_PORT=`/bin/grep wtg.config.wse_server_port ${WCG_INSTALL_DIR}/config/records.config  | grep -v "^#" | awk '{print $4}'`
echo "Filtering Service Port = $FILTERING_SERVICE_PORT"
echo

# Peek into the config file for Download Service 
#DATABASE_DOWNLOAD_SERVER_IP=`/bin/grep WebsenseDDS ${WCG_INSTALL_DIR}/bin/downloadservice.ini | grep -v "^#"  | awk -F = '{print $2}'`
#echo "Database Download Server IP = $DATABASE_DOWNLOAD_SERVER_IP"
#echo

# Test Interfaces
echo "Checking for active network interfaces..."
Interfaces=`awk -F: '/:/{print $1}' /proc/net/dev  | grep eth`
	for Interface in $Interfaces; do
		echo "Interface $Interface:"
		/sbin/ethtool $Interface 
                echo 
                /sbin/ethtool -k $Interface
                # If any interface has scatter-gather on let's flag it as the general recommendation with WCG is to have it off
                SCATTER_GATHER=`/sbin/ethtool -k $Interface | grep -i scatter-gather | grep -c -i on`
                if [ "$SCATTER_GATHER" != 0 ]; then
                    echo
                    echo "WARNING!  scatter-gather is on."
                    echo
                    SCATTER_GATHER_OFF_TEST=FAILED.
                fi
                echo
                /sbin/ifconfig $Interface
                echo
        done

# Test for routing cache or ARP cache overflows
echo "Checking for routing cache overflow errors in /var/log/messages..."
ROUTING_CACHE_OVERFLOWS=`fgrep -i "dst cache overflow" -c /var/log/messages`
if [ "$ROUTING_CACHE_OVERFLOWS" != 0 ]; then
    echo
    echo "WARNING!  Found routing cache overflow entries in /var/log/messages!"
    echo
else
    ROUTING_CACHE_OVERFLOW_TEST=PASSED.
fi
echo "Checking for ARP cache overflow errors in /var/log/messages..."
# NOTE - neighbour is spelled correctly - apparently it's British...
ARP_TABLE_OVERFLOWS=`fgrep -i "neighbour table overflow" -c /var/log/messages`
if [ "$ARP_TABLE_OVERFLOWS" != 0 ]; then
    echo
    echo "WARNING!  Found ARP table overflow entries in /var/log/messages!"
    echo
else
    ARP_CACHE_OVERFLOW_TEST=PASSED.
fi
echo

# Test DNS Servers 
echo "Testing connectivity to DNS name servers listed in /etc/resolv.conf..."
cat /etc/resolv.conf
echo
cat /etc/resolv.conf | grep nameserver | grep -v "^#" | awk '{print $2 " 53"}' | xargs -l /usr/bin/nc -vnuz
DNS_FAILURE_COUNT=`cat /etc/resolv.conf | grep nameserver | grep -v "^#" | awk '{print $2 " 53"}' | xargs -l /usr/bin/nc -vnuz 2>&1 | grep -c -i failed`
if [ "$DNS_FAILURE_COUNT" != 0 ]; then
    DNS_CONNECTIVITY_TEST=FAILED.
fi
echo

# Check the hosts file.  We need the hostname/IP to be the first entry.
HOSTNAME=`hostname`
echo "HOSTNAME = $HOSTNAME"
echo
echo "${WCG_INSTALL_DIR}/bin/content_line -r proxy.node.hostname"
WCG_HOSTNAME=`${WCG_INSTALL_DIR}/bin/content_line -r proxy.node.hostname`
${WCG_INSTALL_DIR}/bin/content_line -r proxy.node.hostname
# Make sure what the system hostname and what WCG thinks is its hostname are the same
if [ "$HOSTNAME" != "$WCG_HOSTNAME" ]; then
    echo
    echo "The system hostname ${HOSTNAME} and the WCG hostname ${WCG_HOSTNAME} do not match!"
    echo
fi
echo
echo "Pinging hostname - should NOT resolve to the loopback (127.0.0.1) address..."
ping -c1 `hostname` 
echo

COUNT=`ping -c 1 -q $HOSTNAME | grep -c 127.0.0.1`
if [ "$COUNT" != 0 ]; then
    echo "WARNING!  Hostname is NOT configured correctly!  Check the hosts file."
    echo
    echo "Checking hosts file..."
    cat /etc/hosts
    echo
else
    HOSTNAME_TEST=PASSED.
fi

# Test Filtering Service connectivity
echo "Testing Filtering Server connectivity configured in ${WCG_INSTALL_DIR}/bin/config/records.config..."
/usr/bin/nc -vnz $FILTERING_SERVICE_IP $FILTERING_SERVICE_PORT
FILTERING_TEST=`/usr/bin/nc -vnz $FILTERING_SERVICE_IP $FILTERING_SERVICE_PORT 2>&1 | grep -c -i failed`
if [ "$FILTERING_TEST" = 0 ]; then
    FILTERING_SERVER_CONNECTIVITY_TEST=PASSED.
else
    echo
    echo "WARNING!  Connectivity to the filtering server (${FILTERING_SERVICE_IP}:${FILTERING_SERVICE_PORT}) failed!"
    echo
fi
/usr/bin/nc -vnz $FILTERING_SERVICE_IP 55807
echo

# Test Policy Server connectivity
echo "Testing Policy Server connectivity configured in ${WCG_INSTALL_DIR}/bin/config/records.config..."
POLICY_SERVER_IP=$RECORDS_CONFIG_POLICY_SERVER_IP
POLICY_SERVER_PORT=$RECORDS_CONFIG_POLICY_SERVER_PORT
/usr/bin/nc -vnz $POLICY_SERVER_IP $POLICY_SERVER_PORT
POLICY_TEST=`/usr/bin/nc -vnz $POLICY_SERVER_IP $POLICY_SERVER_PORT 2>&1 | grep -c -i failed`
if [ "$POLICY_TEST" = 0 ]; then
    POLICY_SERVER_CONNECTIVITY_TEST=PASSED.
else
    echo
    echo "WARNING!  Connectivity to the policy server (${POLICY_SERVER_IP}:${POLICY_SERVER_PORT}) failed!"
    echo
fi
echo

# Test Gateways
# List the routing table, look for lines that begin with a number
# print their gateway, sort them to get unique gateways.  Remove default.
echo "Testing gateway connectivity as listed in the kernel routing table..."
/sbin/route -n | awk '/^[0-9]/{print $2}' | sort | uniq | grep -v 0.0.0.0 | xargs -l ping -qc1
GATEWAY_TEST=`/sbin/route -n | awk '/^[0-9]/{print $2}' | sort | uniq | grep -v 0.0.0.0 | xargs -l ping -qc1 | grep -c 100%`
if [ "$GATEWAY_TEST" = 0 ]; then
    GATEWAY_CONNECTIVITY_TEST=PASSED.
else
    echo
    echo "WARNING!  Connectivity to one of the gateways in the routing table failed!"
    echo
fi

echo
echo "Testing connectivity to www.websense.com"
/usr/bin/nc -vz www.websense.com 80
WEBSENSE_DOT_COM_TEST=`/usr/bin/nc -vz www.websense.com 80 2>&1 | grep -c -i failed`
if [ "$WEBSENSE_DOT_COM_TEST" = 0 ]; then
    WEBSENSE_DOT_COM_CONNECTIVITY_TEST=PASSED.
else
    echo
    echo "WARNING!  Connectivity to www.websense.com failed!"
    echo
fi
echo

# Check to see if content_gateway is running...
echo "Testing to see which WCG processes are running..."
# We don't want grep or tail, etc, to show up in the list of processes...
ps -Af | egrep "content|micro" | egrep -v "grep|tail"
echo

CONTENT_GATEWAY_PID=xxxxxxxxxx
WCG_RUNNING=`ps -Af | egrep -v "nice|tail|grep" | grep -c content_gateway`
if [ "$WCG_RUNNING" = 0 ]; then
    echo
    echo "WARNING!  WCG's content_gateway process is NOT running!"
    echo
elif [ "$WCG_RUNNING" != 1 ]; then
    echo
    echo "WARNING!  There appears to be more than one content_gateway process running!"
    echo
else
    CONTENT_GATEWAY_RUNNING_TEST=PASSED.
    # Grab the process ID for content_gateway for later use...
    CONTENT_GATEWAY_PID=`ps -Af | egrep -v "tail|grep" | grep content_gateway | grep -v "^#" | awk '{print $2}'`
fi

CONTENT_MANAGER_PID=xxxxxxxxxx
CONTENT_MANAGER_RUNNING=`ps -Af | egrep -v "tail|grep" | grep -c content_manager`
if [ "$CONTENT_MANAGER_RUNNING" = 0 ]; then
    echo
    echo "WARNING!  WCG's content_manager process is NOT running!"
    echo
elif [ "$CONTENT_MANAGER_RUNNING" = 1 ]; then
    CONTENT_MANAGER_RUNNING_TEST=PASSED.
    # Grab the process ID for content_manager for later use...
    CONTENT_MANAGER_PID=`ps -Af | egrep -v "tail|grep" | grep content_manager | grep -v "^#" | awk '{print $2}'`
else
    echo
    echo "WARNING!  There appears to be more than one content_manager process running!"
    echo
fi



# Determine which port WCG (content_gateway) is configured to listen on for HTTP traffic
HTTP_PROXY_PORT=`/bin/grep "proxy.config.http.server_port " ${WCG_INSTALL_DIR}/config/records.config  | grep -v "^#" | awk '{print $4}'`
echo "WCG is configured to listen for HTTP proxy traffic on port ${HTTP_PROXY_PORT}"
# Determine which port WCG (microdasys) is configured to listen on for inbound HTTPS traffic
HTTPS_PROXY_PORT=`/bin/grep proxy.config.ssl_inbound_port ${WCG_INSTALL_DIR}/config/records.config  | grep -v "^#" | awk '{print $4}'`
echo "WCG is configured to listen for HTTPS proxy traffic on port ${HTTPS_PROXY_PORT}"
echo

echo "Testing to see if content_manager is listening on the HTTP port $HTTP_PROXY_PORT..."
netstat -tlpn | grep 0.0.0.0:$HTTP_PROXY_PORT
CONTENT_MANAGER_LISTENING=`netstat -tlpn | grep 0.0.0.0:$HTTP_PROXY_PORT | grep -c $CONTENT_MANAGER_PID`
if [ "$CONTENT_MANAGER_LISTENING" != 1 ]; then
    echo
    echo "WARNING!  content_manager is NOT listening on the HTTP proxy port $HTTP_PROXY_PORT"
    echo
else
    HTTP_PORT_LISTENING_TEST=PASSED.
fi
echo

echo

# Test to see if WCG is always using HTTP/1.1
echo "Testing to see if WCG is configured to always send HTTP/1.1 requests..."
SEND_HTTP_11_REQUESTS=`/bin/grep proxy.config.http.send_http11_requests ${WCG_INSTALL_DIR}/config/records.config  | grep -v "^#" | awk '{print $4}'`
if [ "$SEND_HTTP_11_REQUESTS" != 1 ]; then
    echo
    echo "WARNING!  content_gateway is NOT configured to always send HTTP/1.1 requests!"
    echo
else
    SEND_HTTP_11_TEST=PASSED.
fi
echo

# Test to see if chunking is disabled (this is a problem area for WCG)
echo "Testing to see if WCG is configured with chunked transfer encoding disabled..."
CHUNKING_ENABLED=`/bin/grep proxy.config.http.chunking_enabled ${WCG_INSTALL_DIR}/config/records.config  | grep -v "^#" | awk '{print $4}'`
if [ "$CHUNKING_ENABLED" = 1 ]; then
    echo
    echo "WARNING!  content_gateway has chunked transfer endcoding enabled!"
    echo
else
    CHUNKING_DISABLED_TEST=PASSED.
fi
echo

# Test to see which version kernel is running
echo "Checking to see which version Linux kernel is running..."
uname -r
KERNEL_VERSION_2_6=`uname -r | grep -c 2.6.32`
if [ "$KERNEL_VERSION_2_6" != 1 ]; then
    echo
    echo "WARNING!  The current kernel version running is NOT 2.6.32"
    echo
else
    KERNEL_VERSION_TEST=PASSED.
fi
echo

# Test to see if arm is enabled
echo "Testing to see if ARM (transparent proxying) is enabled..."
ARM_ENABLED=`/bin/grep proxy.config.arm.enabled ${WCG_INSTALL_DIR}/config/records.config  | grep -v "^#" | awk '{print $4}'`
# If arm is enabled then check to see if the arm module loaded properly
if [ "$ARM_ENABLED" = 1 ]; then
    echo
    echo "ARM is enabled.  Checking to see if the ARM module is loaded..."
    ARM_ENABLED_TEST=PASSED.
    ARM_LOADED=`/sbin/lsmod | grep -c armlkm26`
    if [ "$ARM_LOADED" = 0 ]; then
        echo
        echo "WARNING!  arm is enabled but the arm module is not loaded!"
        echo
    else
        ARM_LOADED_TEST=PASSED.
        echo "ARM module armlkm is loaded."
    fi
else
    echo "WARNING!  ARM is NOT enabled."
fi
echo

# Check to see if we can find any remnants of crashes/resets
echo "Checking to see if there are any indications of WCG resets or crashes..."
NUM_OF_STACK_TRACES_FOUND=`fgrep -c "STACK TRACE" ${WCG_INSTALL_DIR}/logs/content_gateway.out`
if [ "$NUM_OF_STACK_TRACES_FOUND" != 0 ]; then
    echo
    echo "WARNING!  Found ${NUM_OF_STACK_TRACES_FOUND} stack traces in ${WCG_INSTALL_DIR}/logs/content_gateway.out"
    UNIQUE_STACK_TRACES_FOUND=`fgrep "STACK TRACE" ${WCG_INSTALL_DIR}/logs/content_gateway.out | uniq | grep -c "STACK TRACE"`
    echo "          Of the ${NUM_OF_STACK_TRACES_FOUND} it appears ${UNIQUE_STACK_TRACES_FOUND} are unique."
    echo
else
    CRASH_FINDING_TEST=PASSED.
fi
echo

# Test proxy filtering
export http_proxy=${HOSTNAME}:${HTTP_PROXY_PORT}
export https_proxy=${HOSTNAME}:${HTTPS_PROXY_PORT}

echo "http_proxy = ${http_proxy}"
echo "https_proxy = ${https_proxy}"

echo
echo "Testing HTTP web request through ${HOSTNAME}:${HTTP_PROXY_PORT}. Should see 200 OK"
wget http://testdatabase.websense.com --delete-after
echo
echo "Testing HTTPS web request through ${HOSTNAME}:${HTTPS_PROXY_PORT}. Should see 200 OK"
wget https://testdatabase.websense.com --delete-after --no-check-certificate
echo
echo "Testing adult material category web request through ${HOSTNAME}:${HTTP_PROXY_PORT}.  Should see 302 Redirect to $FILTERING_SERVICE_IP."
wget http://testdatabase.websense.com/adultmaterial/ --delete-after 
echo
echo "Testing real time malicious category web request through ${HOSTNAME}:${HTTP_PROXY_PORT}. Should see 302 Redirect to $FILTERING_SERVICE_IP."
wget http://testdatabase.websense.com/realtime/maliciouswebsites/exploit.html --delete-after
echo
echo "Testing random web request through ${HOSTNAME}:${HTTP_PROXY_PORT}. Should see 200 OK"
wget http://random.yahoo.com/bin/ryl --delete-after
echo

# List all the test results here...
echo
echo
echo "Health check test results..."
echo
echo -e "Test to verify the policy server IPs in records.config and websense.ini match...\t$POLICY_SERVER_IP_MATCH_TEST"
if [ "$POLICY_SERVER_IP_MATCH_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify which is the correct policy server IP that this WCG should be using."
    echo -e "\t        Check the policy server port IP address in ${WCG_INSTALL_DIR}/config/records.config:"
    echo -e "\t            LOCAL wtg.config.policy_server_ip STRING XXX.XXX.XXX.XXX"
    echo -e "\t        and in ${WCG_INSTALL_DIR}/websense.ini:"
    echo -e "\t            PolicyServerIP=XXX.XXX.XXX.XXX"
    echo
fi
echo -e "Test to verify the policy server ports in records.config and websense.ini match...\t$POLICY_SERVER_PORT_MATCH_TEST"
if [ "$POLICY_SERVER_PORT_MATCH_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify which is the correct policy server port that this WCG should be using."
    echo -e "\t        Check the policy server port value in ${WCG_INSTALL_DIR}/config/records.config:"
    echo -e "\t            LOCAL wtg.config.policy_server_port INT XXXXX"
    echo -e "\t        and in ${WCG_INSTALL_DIR}/websense.ini:"
    echo -e "\t            PolicyServerPort=XXXXX"
    echo -e "\t        There is generally no reason why this port shouldn't be set to 55806."
    echo
fi
echo -e "Test to verify scatter-gather is off...\t\t\t\t\t\t\t$SCATTER_GATHER_OFF_TEST"
if [ "$SCATTER_GATHER_OFF_TEST" = "FAILED." ]; then
    echo -e "\tACTION: It is recommended that scatter-gather be turned off for all interfaces WCG is using."
    echo -e "\t        Use ethtool -K to turn scatter-gather off on the appropriate interfaces."
    echo   
fi
echo -e "Test to look for routing cache errors...\t\t\t\t\t\t$ROUTING_CACHE_OVERFLOW_TEST"
if [ "$ROUTING_CACHE_OVERFLOW_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify the routing cache size is appropriate for the given amount of system memory."
    echo -e "\t        It is recommended that you remove the following entries from /etc/sysctl.conf:"
    echo -e "\t            net.ipv4.route.max_size"
    echo -e "\t            net.ipv4.route.gc_thresh"
    echo -e "\t        This will allow the system to dynamically determine an appropriate size.  Typically,"
    echo -e "\t        you will only see routing cache overflow errors when on a very large LAN/subnet with"
    echo -e "\t        a lot of IP addresses being run through WCG."
    echo   
fi
echo -e "Test to look for ARP cache errors...\t\t\t\t\t\t\t$ARP_CACHE_OVERFLOW_TEST"
if [ "$ARP_CACHE_OVERFLOW_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify the ARP cache size is appropriate for the given amount of system memory."
    echo -e "\t        It is recommended that you remove the following entry from /etc/sysctl.conf:"
    echo -e "\t            net.ipv4.neigh.default.gc_thresh3"
    echo -e "\t        This will allow the system to dynamically determine an appropriate size.  Typically,"
    echo -e "\t        you will only see ARP cache overflow errors when a lot of devices are on the local link"
    echo -e "\t        thus producing a lot of ARP requests."
    echo   
fi
echo -e "Test to verify DNS server connectivity...\t\t\t\t\t\t$DNS_CONNECTIVITY_TEST"
if [ "$DNS_CONNECTIVITY_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that all of the nameservers listed in /etc/conf are accessible."
    echo -e "\t        Use a tool like nc (netcat) or ping to see if you can reach and connect to each DNS server."
    echo
fi
echo -e "Test to verify hostname is configured properly in the hosts file...\t\t\t$HOSTNAME_TEST"
if [ "$HOSTNAME_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that the hostname and IP is the first entry in the /etc/hosts file."
    echo -e "\t        The hostname should NOT be in the same entry as the loopback (127.0.0.1)/localhost entry."
    echo
fi
echo -e "Test to verify connectivity with the policy server...\t\t\t\t\t$POLICY_SERVER_CONNECTIVITY_TEST"
if [ "$POLICY_SERVER_CONNECTIVITY_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that the policy server can be accessed via the network."
    echo -e "\t        Using the policy server IP address and port (${POLICY_SERVER_IP}:${POLICY_SERVER_PORT} use tools"
    echo -e "\t        like ping, nc (netcat) or telnet to verify you can connect to the policy server from the WCG box."
    echo -e "\t        If connectivity fails verify using netstat on the policy server machine that it's listening on"
    echo -e "\t        the policy server port (${POLICY_SERVER_PORT}).  Try using tracert to see if there are any intermediate"
    echo -e "\t        hops between WCG and the policy server where a firewall could be blocking access, etc."
    echo
fi
echo -e "Test to verify connectivity with the filtering server...\t\t\t\t$FILTERING_SERVER_CONNECTIVITY_TEST"
if [ "$FILTERING_SERVER_CONNECTIVITY_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that the filtering server can be accessed via the network."
    echo -e "\t        Using the filtering server IP address and port (${FILTERING_SERVICE_IP}:${FILTERING_SERVICE_PORT}) use tools"
    echo -e "\t        like ping, nc (netcat) or telnet to verify you can connect to the policy server from the WCG box."
    echo -e "\t        If connectivity fails verify using netstat on the filtering server machine that it's listening on"
    echo -e "\t        the filtering server port (${FILTERING_SERVICE_PORT}).  Try using tracert to see if there are any intermediate"
    echo -e "\t        hops between WCG and the filtering server where a firewall could be blocking access, etc."
    echo
fi
echo -e "Test to verify connectivity with the gateways listed in the routing table...\t\t$GATEWAY_CONNECTIVITY_TEST"
if [ "$GATEWAY_CONNECTIVITY_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that the gateways listed in the routing table can be accessed via the network."
    echo -e "\t        Use route -n to list the gateways in the routing table and then verify with a network administrator"
    echo -e "\t        that the network configuration of this machine is correct.  Use tools like ping verify you can reach"
    echo -e "\t        the configured gateways."
    echo
fi
echo -e "Test to verify content_gateway is running...\t\t\t\t\t\t$CONTENT_GATEWAY_RUNNING_TEST"
if [ "$CONTENT_GATEWAY_RUNNING_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that the content gateway has started correctly.  Use tools like ps to determine if it is running."
    echo -e "\t        Use the WCGAdmin script to check the current status - i.e. ${WCG_INSTALL_DIR}/WCGAdmin start|stop|status."
    echo -e "\t        Also check system logs such as /var/log/messages for any additional info."
    echo
fi
echo -e "Test to verify content_manager is running...\t\t\t\t\t\t$CONTENT_MANAGER_RUNNING_TEST"
if [ "$CONTENT_MANAGER_RUNNING_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that the content manager has started correctly.  Use tools like ps to determine if it is running."
    echo -e "\t        Use the WCGAdmin script to check the current status - i.e. ${WCG_INSTALL_DIR}/WCGAdmin start|stop|status."
    echo -e "\t        Also check system logs such as /var/log/messages for any additional info."
    echo
fi
echo -e "Test to verify content_manager is listening on the HTTP port $HTTP_PROXY_PORT...\t\t\t$HTTP_PORT_LISTENING_TEST"
if [ "$HTTP_PORT_LISTENING_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that the content_manager process is listening on port $HTTP_PROXY_PORT."
    echo -e "\t        Use netstat -tlpn to determine which process is listening on that port.  You may need to switch to"
    echo -e "\t        if that port is already taken.  If so, modify ${WCG_INSTALL_DIR}/config/records.config:"
    echo -e "\t            CONFIG proxy.config.http.server_port INT XXXXX"
    echo
fi
echo -e "Test to verify content_gateway is always sending HTTP/1.1 requests...\t\t\t$SEND_HTTP_11_TEST"
if [ "$SEND_HTTP_11_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that WCG is configured to always send HTTP/1.1 requests.  This is the recommended setting."
    echo -e "\t        Check the send_http11_requests setting in ${WCG_INSTALL_DIR}/config/records.config:"
    echo -e "\t            CONFIG proxy.config.http.send_http11_requests INT X"
    echo -e "\t        This value should be set to 1 which means always."
    echo
fi
echo -e "Test to verify content_gateway has chunked transfer encoding disabled...\t\t$CHUNKING_DISABLED_TEST"
if [ "$CHUNKING_DISABLED_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that WCG is configured with chunked transfer encoding disabled.  This is the recommended setting."
    echo -e "\t        Check the chunking_enabled setting in ${WCG_INSTALL_DIR}/config/records.config:"
    echo -e "\t            CONFIG proxy.config.http.chunking_enabled INT X"
    echo -e "\t        This value should be set to 0 which means chunking is disabled."
    echo
fi
echo -e "Test to verify the required kernel version is running...\t\t\t\t$KERNEL_VERSION_TEST"
if [ "$KERNEL_VERSION_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that OS kernel version installed is the required 2.6.9 kernel.  Use uname -r for verification."
    echo -e "\t        For transparent proxying and arm module usage the required kernel version is 2.6.9."
    echo
fi
echo -e "Test to verify ARM is enabled...\t\t\t\t\t\t\t$ARM_ENABLED_TEST"
if [ "$ARM_ENABLED_TEST" = "FAILED." ]; then
    echo -e "\tACTION: Verify that WCG is configured with ARM enabled.  This is the recommended setting."
    echo -e "\t        Check the arm.enabled setting in ${WCG_INSTALL_DIR}/config/records.config:"
    echo -e "\t            CONFIG proxy.config.arm.enabled INT X"
    echo -e "\t        This value should be set to 1 regardless of whether or not transparent/WCCP proxying"
    echo -e "\t        is being used."
    echo
fi
if [ "$ARM_ENABLED" = 1 ]; then
    echo -e "Test to verify the arm module is loaded...\t\t\t\t\t\t$ARM_LOADED_TEST"
    if [ "$ARM_LOADED_TEST" = "FAILED." ]; then
        echo -e "\tACTION: Verify that OS kernel version installed is the required 2.6.9 kernel.  Use uname -r for verification."
        echo -e "\t        For transparent proxying and arm module usage the required kernel version is 2.6.9."
        echo -e "\t        Use /sbin/lsmod to list the loaded kernel modules.  The WCG arm module is named armlkm26."
        echo
    fi
fi
echo -e "Test to find indications of WCG crashes or resets...\t\t\t\t\t$CRASH_FINDING_TEST"
if [ "$CRASH_FINDING_TEST" = "FAILED." ]; then
    echo -e "\tACTION: There are indications of crashes/resets in ${WCG_INSTALL_DIR}/logs/content_gateway.out."
    echo -e "\t        Use grep to search through content_gateway.out or /var/log/messages for entries indicating"
    echo -e "\t        why content_gateway could be crashing.  Likely causes are memory exhaustion.  Verify sufficient"
    echo -e "\t        memory is installed on the system.  Use top to see which processes are consuming the most memory."
    echo
fi
echo
