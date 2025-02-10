#!/opt/bin/env bash

cat /dev/null > /opt/etc/unblock.dnsmasq

while read line || [ -n "$line" ]; do

  [ -z "$line" ] && continue
  [ "${line:0:1}" = "#" ] && continue

  echo $line | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue

  echo "ipset=/$line/unblock" >> /opt/etc/unblock.dnsmasq

done < /opt/etc/unblock.txt


while read line || [ -n "$line" ]; do

  [ -z "$line" ] && continue
  [ "${line:0:1}" = "#" ] && continue

  echo $line | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue

  echo "ipset=/$line/unblockvpn" >> /opt/etc/unblock.dnsmasq

done < /opt/etc/unblockvpn.txt
