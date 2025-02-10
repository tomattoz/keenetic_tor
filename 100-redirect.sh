#!/opt/bin/env bash

[ "$type" == "ip6tables" ] && exit 0
[ "$table" != "nat" ] && exit 0

if [ -z "$(iptables-save 2>/dev/null | grep unblock)" ]; then
    ipset create unblock hash:net -exist
    iptables -w -t nat -A PREROUTING -i br0 -p tcp -m set --match-set unblock dst -j REDIRECT --to-port 9141

    # unblock guest network
    #iptables -w -t nat -A PREROUTING -i br1 -p tcp -m set --match-set unblock dst -j REDIRECT --to-port 9141
fi

if [ -z "$(iptables-save 2>/dev/null | grep "udp \-\-dport 53 \-j DNAT")" ]; then
    iptables -w -t nat -I PREROUTING -i br0 -p udp --dport 53 -j DNAT --to 192.168.1.1

    # unblock guest network
    #iptables -w -t nat -I PREROUTING -i br1 -p udp --dport 53 -j DNAT --to 192.168.1.1
fi

if [ -z "$(iptables-save 2>/dev/null | grep "tcp \-\-dport 53 \-j DNAT")" ]; then
    iptables -w -t nat -I PREROUTING -i br0 -p tcp --dport 53 -j DNAT --to 192.168.1.1

    # unblock guest network
    #iptables -w -t nat -I PREROUTING -i br1 -p tcp --dport 53 -j DNAT --to 192.168.1.1
fi


if [ -z "$(iptables-save 2>/dev/null | grep unblockvpn)" ]; then
    ipset create unblockvpn hash:net -exist
    iptables -I PREROUTING -w -t nat -i br0 -p tcp -m set --match-set unblockvpn dst -j MASQUERADE -o ppp0
    iptables -I PREROUTING -w -t nat -i br0 -p udp -m set --match-set unblockvpn dst -j MASQUERADE -o ppp0
    iptables -t nat -A PREROUTING -i br0 -p tcp -m set --match-set unblockvpn dst -j MASQUERADE -o ppp0
#    iptables -t nat -A OUTPUT -p tcp -m set --match-set unblockvpn dst -j MASQUERADE -o ppp0

#    iptables -I PREROUTING -w -t nat -i sstp0 -p tcp -m set --match-set unblockvpn dst -j MASQUERADE -o ppp0
#    iptables -I PREROUTING -w -t nat -i sstp0 -p udp -m set --match-set unblockvpn dst -j MASQUERADE -o ppp0
#    iptables -t nat -A PREROUTING -i sstp0 -p tcp -m set --match-set unblockvpn dst -j MASQUERADE -o ppp0

fi

exit 0
