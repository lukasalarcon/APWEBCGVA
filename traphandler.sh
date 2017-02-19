#!/bin/bash
set -x
#eck_root_disk.sh

# Setup variables
unitSize=$(snmpget -v2c -c public localhost hrStorageAllocationUnits.4 | awk '{print $(NF - 1)}')
totalSize=$(snmpget -v2c -c public localhost hrStorageSize.4 | awk '{print $NF}')
totalUsed=$(snmpget -v2c -c public localhost hrStorageUsed.4 | awk '{print $NF}')

# Find the difference
totalFree=$(( totalSize - totalUsed ))

# Convert to real money
totalFree=$(( totalFree * unitSize ))


snmptrap -v 1 -c public 10.178.2.109 .1.3.6.1 wsga 6 17 '' .1.3.6.1 s "Total Free space $totalFree"


# If less than 25% is free, raise an alert
#[[ ${totalFree} -lt $(( ((totalSize * unitSize) / 100) * 25 )) ]] && {
  # handle error here, maybe:
  #snmptrap -v 1 -c public 10.178.2.109 .1.3.6.1 wsga 6 17 '' .1.3.6.1 s "Total Free space $totalFree" 
#}

exit 0
