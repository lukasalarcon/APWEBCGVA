#!/bin/sh
 
RE_IPV4="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])"
 
posixregex -r "^(${RE_IPV4})$" \
   127.0.0.1 \
   10.0.0.1 \
   192.168.1.1 \
   0.0.0.0 \
   255.255.255.255 \
   |sed -e 's/not found/fail/g' -e 's/found/pass/g' \
   |awk '{print$4" "$3" "$2}' \
   |sed -e 's/^/IPv4 Pass: /g'
echo ""
posixregex -r "^(${RE_IPV4})$" \
   10002.3.4 \
   1.2.3.4.5 \
   256.0.0.0 \
   260.0.0.0 \
   |sed -e 's/not found/fail/g' -e 's/found/pass/g' \
   |awk '{print$4" "$3" "$2}' \
   |sed -e 's/^/IPv4 Fail: /g'
echo ""
 
SEG="[0-9a-fA-F]{1,4}"
 
RE_IPV6="([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|"                    # TEST: 1:2:3:4:5:6:7:8
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,7}:|"                         # TEST: 1::                              1:2:3:4:5:6:7::
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|"         # TEST: 1::8             1:2:3:4:5:6::8  1:2:3:4:5:6::8
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|"  # TEST: 1::7:8           1:2:3:4:5::7:8  1:2:3:4:5::8
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|"  # TEST: 1::6:7:8         1:2:3:4::6:7:8  1:2:3:4::8
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|"  # TEST: 1::5:6:7:8       1:2:3::5:6:7:8  1:2:3::8
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|"  # TEST: 1::4:5:6:7:8     1:2::4:5:6:7:8  1:2::8
RE_IPV6="${RE_IPV6}[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|"       # TEST: 1::3:4:5:6:7:8   1::3:4:5:6:7:8  1::8
RE_IPV6="${RE_IPV6}:((:[0-9a-fA-F]{1,4}){1,7}|:)|"                     # TEST: ::2:3:4:5:6:7:8  ::2:3:4:5:6:7:8 ::8       ::     
RE_IPV6="${RE_IPV6}fe08:(:[0-9a-fA-F]{1,4}){2,2}%[0-9a-zA-Z]{1,}|"     # TEST: fe08::7:8%eth0      fe08::7:8%1                                      (link-local IPv6 addresses with zone index)
RE_IPV6="${RE_IPV6}::(ffff(:0{1,4}){0,1}:){0,1}${RE_IPV4}|"            # TEST: ::255.255.255.255   ::ffff:255.255.255.255  ::ffff:0:255.255.255.255 (IPv4-mapped IPv6 addresses and IPv4-translated addresses)
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,4}:${RE_IPV4}"                # TEST: 2001:db8:3:4::192.0.2.33  64:ff9b::192.0.2.33                        (IPv4-Embedded IPv6 Address)
 
TEST_STRINGS=`grep '# TEST: ' $0 |grep -v grep  |cut -d# -f 2 |cut -d\( -f1 |sed -e 's/^ TEST: //g'`
 
posixregex -r "^(${RE_IPV6})$" \
   1:2:3:4:5:6:7:8 \
   ::ffff:10.0.0.1 \
   ::ffff:1.2.3.4 \
   ::ffff:0.0.0.0 \
   1:2:3:4:5:6:77:88 \
   ::ffff:255.255.255.255 \
   fe08::7:8 \
   ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff \
   |sed -e 's/not found/fail/g' -e 's/found/pass/g' \
   |awk '{print$4" "$3" "$2}' \
   |sed -e 's/^/IPv6 Pass: /g'
echo ""
posixregex -r "^(${RE_IPV6})$" \
   ${TEST_STRINGS} \
   |sed -e 's/not found/fail/g' -e 's/found/pass/g' \
   |awk '{print$4" "$3" "$2}' \
   |sed -e 's/^/IPv6 Test: /g'
echo ""
posixregex -r "^(${RE_IPV6})$" \
   1:2:3:4:5:6:7:8:9 \
   1:2:3:4:5:6::7:8 \
   :1:2:3:4:5:6:7:8 \
   1:2:3:4:5:6:7:8: \
   ::1:2:3:4:5:6:7:8 \
   1:2:3:4:5:6:7:8:: \
   1:2:3:4:5:6:7:88888 \
   2001:db8:3:4:5::192.0.2.33 \
   fe08::7:8% \
   fe08::7:8i \
   fe08::7:8interface \
   |sed -e 's/not found/fail/g' -e 's/found/pass/g' \
   |awk '{print$4" "$3" "$2}' \
   |sed -e 's/^/IPv6 Fail: /g'
echo ""
