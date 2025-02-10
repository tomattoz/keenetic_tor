#!/opt/bin/env bash

ipset flush unblock
ipset flush unblockvpn

/opt/bin/unblock_dnsmasq.sh
/opt/etc/init.d/S56dnsmasq restart
/opt/bin/unblock_ipset.sh &
