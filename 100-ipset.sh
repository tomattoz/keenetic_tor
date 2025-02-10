#!/opt/bin/env bash

[ "$1" != "start" ] && exit 0

ipset create unblock hash:net -exist
ipset create unblockvpn hash:net -exist

exit 0
