#!/opt/bin/env ash

[ "$1" != "start" ] && exit 0

ipset create unblock hash:net -exist

exit 0
