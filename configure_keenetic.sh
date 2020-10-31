#!/opt/bin/bash

if [[ $DEBUG -eq '1' ]]; then
    set -x
fi

# 8/16 Color vraibles:
TXT_GRN='\e[0;32m'
TXT_RED='\e[0;31m'
TXT_YLW='\e[0;33m'
TXT_BLUE='\e[0;34m'
TXT_RST='\e[0m'

WGET='/opt/bin/wget -q --no-check-certificate'

github_link='https://raw.githubusercontent.com/elky92'

lanip=$(ndmq -p 'show interface Bridge0' -P address)

### Functions for output formatted text
function echo_OK()
{
    echo -e "   ${TXT_GRN}OK${TXT_RST}"
}

function echo_FAIL()
{
    echo -e "   ${TXT_RED}FAIL${TXT_RST}"
}

function echo_RESULT()
{
    local result=$*
    if [[ "$result" -eq 0 ]]; then
        echo_OK
    else
        echo_FAIL
        return 1
    fi
}

function confirm_reboot()
{
    # call with a prompt string or use a default
    read -r -p "${1:-Are you want to reboot now? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

case "$1" in
    remove)
        opkg remove --force-depends --force-removal-of-dependent-packages --autoremove tor tor-geoip bind-dig dnsmasq-full ipset iptables dnscrypt-proxy2
        rm -rf /opt/etc/tor
        rm -f /opt/etc/ndm/fs.d/100-ipset.sh
        rm -f /opt/etc/unblock.txt
        rm -f /opt/etc/unblock.dnsmasq
        rm -f /opt/bin/unblock_ipset.sh
        rm -f /opt/bin/unblock_dnsmasq.sh
        rm -f /opt/bin/update_dnsmasq.sh
        rm -f /opt/etc/init.d/S99unblock
        rm -f /opt/etc/ndm/netfilter.d/100-redirect.sh
        rm -f /opt/etc/dnsmasq.conf
        rm -f /opt/etc/dnscrypt-proxy.toml
        rm -f /opt/etc/cron.d/ipsec
        rm -f /opt/etc/dnsmasq.conf
        rm -f /opt/etc/hosts.dnsmasq
        rm -f /opt/bin/configure_keenetic.sh

        ndmq -p 'no opkg dns-override'
        ndmq -p 'system configuration save'
        confirm_reboot && ndmq -p 'system reboot'
    ;;
    dnscrypt)
        if [[ ! -f /opt/etc/init.d/S99unblock ]]; then
            echo "Ошибка! Основной метод обхода блокировок не реализован в системе. Запустите configure_keenetic.sh без параметров."
            exit 1
        fi

        opkg update
        opkg install dnscrypt-proxy2
        echo_RESULT $?

        rm -f /opt/etc/dnscrypt-proxy.toml
        echo -en "$WGET -O /opt/etc/dnscrypt-proxy.toml $github_link/configure_keenetic/master/dnscrypt-proxy.toml  ...    "
        $WGET -O /opt/etc/dnscrypt-proxy.toml $github_link/configure_keenetic/master/dnscrypt-proxy.toml
        /opt/etc/init.d/S09dnscrypt-proxy2 start
        echo_RESULT $?

        rm -f /opt/bin/unblock_ipset.sh
        echo -en "$WGET -O /opt/bin/unblock_ipset.sh $github_link/configure_keenetic/master/unblock_ipset_dnscrypt.sh...    "
        $WGET -O /opt/bin/unblock_ipset.sh $github_link/configure_keenetic/master/unblock_ipset_dnscrypt.sh
        echo_RESULT $?
        chmod +x /opt/bin/unblock_ipset.sh

        rm -f /opt/bin/unblock_dnsmasq.sh
        echo -en "$WGET -O /opt/bin/unblock_dnsmasq.sh $github_link/configure_keenetic/master/unblock_dnsmasq_dnscrypt.sh...    "
        $WGET -O /opt/bin/unblock_dnsmasq.sh $github_link/configure_keenetic/master/unblock_dnsmasq_dnscrypt.sh
        echo_RESULT $?
        chmod +x /opt/bin/unblock_dnsmasq.sh

        /opt/bin/update_dnsmasq.sh 
        echo_RESULT $?
    ;;
    dnsmasq)
        opkg update
        opkg install bind-dig dnsmasq-full cron
        echo_RESULT $?

        rm -f /opt/etc/dnsmasq.conf
        echo -en "$WGET -O /opt/etc/dnsmasq.conf $github_link/configure_keenetic/master/dnsmasq_dnsmasq.conf...    "
        $WGET -O /opt/etc/dnsmasq.conf $github_link/configure_keenetic/master/dnsmasq_dnsmasq.conf
        echo_RESULT $?
        sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/dnsmasq.conf

        rm -f /opt/etc/hosts.dnsmasq
        echo -en "$WGET -O /opt/etc/hosts.dnsmasq $github_link/configure_keenetic/master/hosts.dnsmasq...    "
        $WGET -O /opt/etc/hosts.dnsmasq $github_link/configure_keenetic/master/hosts.dnsmasq
        echo_RESULT $?

        echo -en "Starting dnsmasq...    "
        /opt/etc/init.d/S56dnsmasq restart
        echo_RESULT $?

        ndmq -p 'opkg dns-override'
        ndmq -p 'system configuration save'
    ;;
    *)
        opkg update
        opkg install tor tor-geoip bind-dig dnsmasq-full ipset iptables cron
        echo_RESULT $?

        set_type="hash:net"

        ipset create testset $set_type -exist > /dev/null 2>&1
        retVal=$?
        if [[ $retVal -ne 0 ]]; then
            set_type="hash:ip"
        fi

        rm -f /opt/etc/ndm/fs.d/100-ipset.sh
        echo -en "$WGET -O /opt/etc/ndm/fs.d/100-ipset.sh $github_link/configure_keenetic/master/100-ipset.sh...    "
        $WGET -O /opt/etc/ndm/fs.d/100-ipset.sh $github_link/configure_keenetic/master/100-ipset.sh
        echo_RESULT $?
        chmod +x /opt/etc/ndm/fs.d/100-ipset.sh
        sed -i "s/hash:net/${set_type}/g" /opt/etc/ndm/fs.d/100-ipset.sh

        rm -f /opt/etc/tor/torrc
        echo -en "$WGET -O /opt/etc/tor/torrc $github_link/configure_keenetic/master/torrc...    "
        $WGET -O /opt/etc/tor/torrc $github_link/configure_keenetic/master/torrc
        echo_RESULT $?
        sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/tor/torrc

        rm -f /opt/etc/unblock.txt
        echo -en "$WGET -O /opt/etc/unblock.txt $github_link/configure_keenetic/master/unblock.txt...    "
        $WGET -O /opt/etc/unblock.txt $github_link/configure_keenetic/master/unblock.txt
        echo_RESULT $?

        rm -f /opt/bin/unblock_ipset.sh
        echo -en "$WGET -O /opt/bin/unblock_ipset.sh $github_link/configure_keenetic/master/unblock_ipset.sh...    "
        $WGET -O /opt/bin/unblock_ipset.sh $github_link/configure_keenetic/master/unblock_ipset.sh
        echo_RESULT $?
        chmod +x /opt/bin/unblock_ipset.sh

        rm -f /opt/bin/unblock_dnsmasq.sh
        echo -en "$WGET -O /opt/bin/unblock_dnsmasq.sh $github_link/configure_keenetic/master/unblock_dnsmasq.sh...    "
        $WGET -O /opt/bin/unblock_dnsmasq.sh $github_link/configure_keenetic/master/unblock_dnsmasq.sh
        echo_RESULT $?
        chmod +x /opt/bin/unblock_dnsmasq.sh

        /opt/bin/unblock_dnsmasq.sh
        echo_RESULT $?

        rm -f /opt/bin/update_dnsmasq.sh
        echo -en "$WGET -O /opt/bin/update_dnsmasq.sh $github_link/configure_keenetic/master/update_dnsmasq.sh...    "
        $WGET -O /opt/bin/update_dnsmasq.sh $github_link/configure_keenetic/master/update_dnsmasq.sh
        echo_RESULT $?
        chmod +x /opt/bin/update_dnsmasq.sh

        rm -f /opt/etc/cron.daily/backup
        echo -en "$WGET -O /opt/etc/cron.daily/backup $github_link/configure_keenetic/master/backup...    "
        $WGET -O /opt/etc/cron.daily/backup $github_link/configure_keenetic/master/backup
        echo_RESULT $?
        chmod 600 /opt/etc/cron.daily/backup

        rm -f /opt/etc/init.d/S99unblock
        echo -en "$WGET -O /opt/etc/init.d/S99unblock $github_link/configure_keenetic/master/S99unblock...    "
        $WGET -O /opt/etc/init.d/S99unblock $github_link/configure_keenetic/master/S99unblock
        echo_RESULT $?
        chmod +x /opt/etc/init.d/S99unblock
        sed -i "s/hash:net/${set_type}/g" /opt/etc/init.d/S99unblock
        sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/init.d/S99unblock

        rm -f /opt/etc/ndm/netfilter.d/100-redirect.sh
        echo -en "$WGET -O /opt/etc/ndm/netfilter.d/100-redirect.sh $github_link/configure_keenetic/master/100-redirect.sh...    "
        $WGET -O /opt/etc/ndm/netfilter.d/100-redirect.sh $github_link/configure_keenetic/master/100-redirect.sh
        echo_RESULT $?
        chmod +x /opt/etc/ndm/netfilter.d/100-redirect.sh
        sed -i "s/hash:net/${set_type}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
        sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh

        rm -f /opt/etc/dnsmasq.conf
        echo -en "$WGET -O /opt/etc/dnsmasq.conf $github_link/configure_keenetic/master/dnsmasq.conf...    "
        $WGET -O /opt/etc/dnsmasq.conf $github_link/configure_keenetic/master/dnsmasq.conf
        echo_RESULT $?
        sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/dnsmasq.conf

        rm -f /opt/etc/hosts.dnsmasq
        echo -en "$WGET -O /opt/etc/hosts.dnsmasq $github_link/configure_keenetic/master/hosts.dnsmasq...    "
        $WGET -O /opt/etc/hosts.dnsmasq $github_link/configure_keenetic/master/hosts.dnsmasq
        echo_RESULT $?

        if [[ ! -d '/opt/etc/cron.d' ]]; then
            mkdir -p /opt/etc/cron.d
        fi
        echo -e "00 06 * * * root /opt/bin/unblock_ipset.sh\n" > /opt/etc/cron.d/ipsec
        chmod 600 /opt/etc/cron.d/ipsec

        ndmq -p 'opkg dns-override'
        ndmq -p 'system configuration save'
        confirm_reboot && ndmq -p 'system reboot'

        sleep 5
    ;;
esac

if [[ $DEBUG -eq '1' ]]; then
    set +x
fi

exit 0
