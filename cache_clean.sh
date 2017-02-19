#!/bin/bash 

find / -name WCGAdmin > FoundWCG.txt

WcG=`head -1 FoundWCG.txt`

myWcGPath="$(dirname "$WcG")"
 

if [ "$WcG" == "" ]; then
 exit 1
fi


#this script is used for clearing cache automatically. 

echo -e "\n[`date`]: CACHE CLEAN ROUTINE [BEGIN] ====" 
echo -e "\n[`date`]: STOP WCG ----\n" 
$myWcGPath/./WCGAdmin stop 

echo -e "\n[`date`]: CLEAN CACHE ----\n" 
$myWcGPath/bin/./content_gateway -Cclear 

echo -e "\n[`date`]: START WCG ----\n" 
$myWcGPath/./WCGAdmin start 

echo -e "\n[`date`]: CACHE CLEAN ROUTINE [END] ====" 
