#!/opt/bin/env bash

if [[ "$DEBUG" -eq '1' ]]; then
    set -x
fi

# 8/16 Color vraibles:
TXT_GRN='\e[0;32m'
TXT_RED='\e[0;31m'
TXT_YLW='\e[0;33m'
TXT_BLUE='\e[0;34m'
TXT_RST='\e[0m'

WGET='/opt/bin/wget -q --no-check-certificate'
github_link='https://raw.githubusercontent.com/PsychodelEKS/unblock_keenetic/master'
lanip=$(wget -qO- localhost:79/rci/show/interface/Bridge0/address)

temp="${temp%\"}"
temp="${temp#\"}"

function rci_post()
{
    wget -qO - --post-data='$1' localhost:79/rci/ > /dev/null 2>&1
}

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
    read -r -p "${1:-Do you want to reboot now? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

function _remove_dnscrypt()
{
    /opt/etc/init.d/S09dnscrypt-proxy2 stop
    opkg remove --force-depends --force-removal-of-dependent-packages --autoremove dnscrypt-proxy2

    rm -f /opt/etc/dnscrypt-proxy.toml
    rm -f /opt/etc/dnsmasq.conf
    echo -en "$WGET -O /opt/etc/dnsmasq.conf $github_link/dnsmasq.conf...    "
    $WGET -O /opt/etc/dnsmasq.conf $github_link/dnsmasq.conf
    echo_RESULT $?
    sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/dnsmasq.conf

    rm -f /opt/etc/hosts.dnsmasq
    echo -en "$WGET -O /opt/etc/hosts.dnsmasq $github_link/hosts.dnsmasq...    "
    $WGET -O /opt/etc/hosts.dnsmasq $github_link/hosts.dnsmasq
    echo_RESULT $?

    echo -en "Starting dnsmasq...    "
    /opt/etc/init.d/S56dnsmasq restart
    echo_RESULT $?
}

function _remove_kmod()
{
    echo ''
}

function _remove_base_environment()
{
        opkg remove --force-depends --force-removal-of-dependent-packages --autoremove tor tor-geoip bind-dig dnsmasq-full ipset iptables dnscrypt-proxy2 obfs4
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

        rci_post '[{"opkg": {"dns-override": false}},{"system": {"configuration": {"save": true}}}]'
        confirm_reboot && rci_post '[{"system":{"reboot":true}}]'
}

function _install_dnscrypt()
{
        if [[ ! -f /opt/etc/hosts.dnsmasq ]]; then
            echo "Ошибка! Основной метод обхода блокировок не реализован в системе. Запустите configure_keenetic.sh без параметров."
            exit 1
        fi

        opkg update
        opkg install dnscrypt-proxy2
        echo_RESULT $?

        rm -f /opt/etc/dnscrypt-proxy.toml
        echo -en "$WGET -O /opt/etc/dnscrypt-proxy.toml $github_link/dnscrypt-proxy.toml  ...    "
        $WGET -O /opt/etc/dnscrypt-proxy.toml $github_link/dnscrypt-proxy.toml
        /opt/etc/init.d/S09dnscrypt-proxy2 start
        echo_RESULT $?

        rm -f /opt/bin/unblock_ipset.sh
        echo -en "$WGET -O /opt/bin/unblock_ipset.sh $github_link/unblock_ipset_dnscrypt.sh...    "
        $WGET -O /opt/bin/unblock_ipset.sh $github_link/unblock_ipset_dnscrypt.sh
        echo_RESULT $?
        chmod +x /opt/bin/unblock_ipset.sh

        rm -f /opt/bin/unblock_dnsmasq.sh
        echo -en "$WGET -O /opt/bin/unblock_dnsmasq.sh $github_link/unblock_dnsmasq_dnscrypt.sh...    "
        $WGET -O /opt/bin/unblock_dnsmasq.sh $github_link/unblock_dnsmasq_dnscrypt.sh
        echo_RESULT $?
        chmod +x /opt/bin/unblock_dnsmasq.sh

        /opt/bin/update_dnsmasq.sh
        echo_RESULT $?
}

function _install_dnsmasq()
{
        opkg update
        opkg install bind-dig dnsmasq-full cron
        echo_RESULT $?

        rm -f /opt/etc/dnsmasq.conf
        echo -en "$WGET -O /opt/etc/dnsmasq.conf $github_link/dnsmasq.conf...    "
        $WGET -O /opt/etc/dnsmasq.conf $github_link/dnsmasq.conf
        echo_RESULT $?
        sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/dnsmasq.conf

        rm -f /opt/etc/hosts.dnsmasq
        echo -en "$WGET -O /opt/etc/hosts.dnsmasq $github_link/hosts.dnsmasq...    "
        $WGET -O /opt/etc/hosts.dnsmasq $github_link/hosts.dnsmasq
        echo_RESULT $?

        echo -en "Starting dnsmasq...    "
        /opt/etc/init.d/S56dnsmasq restart
        echo_RESULT $?

        rci_post '[{"opkg": {"dns-override": true}},{"system": {"configuration": {"save": true}}}]'
}

function _install_kmod()
{
    echo ''
}

function _install_base_environment()
{
        opkg update
        opkg install tor tor-geoip bind-dig dnsmasq-full ipset iptables cron obfs4
        echo_RESULT $?

        set_type="hash:net"

        ipset create testset $set_type -exist > /dev/null 2>&1
        retVal=$?
        if [[ "$retVal" -ne 0 ]]; then
            set_type="hash:ip"
        fi

        rm -f /opt/etc/ndm/fs.d/100-ipset.sh
        echo -en "$WGET -O /opt/etc/ndm/fs.d/100-ipset.sh $github_link/100-ipset.sh...    "
        $WGET -O /opt/etc/ndm/fs.d/100-ipset.sh $github_link/100-ipset.sh
        echo_RESULT $?
        chmod +x /opt/etc/ndm/fs.d/100-ipset.sh
        sed -i "s/hash:net/${set_type}/g" /opt/etc/ndm/fs.d/100-ipset.sh

        rm -f /opt/etc/tor/torrc
        echo -en "$WGET -O /opt/etc/tor/torrc $github_link/torrc...    "
        $WGET -O /opt/etc/tor/torrc $github_link/torrc
        echo_RESULT $?
        sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/tor/torrc

        rm -f /opt/etc/unblock.txt
        echo -en "$WGET -O /opt/etc/unblock.txt $github_link/unblock.txt...    "
        $WGET -O /opt/etc/unblock.txt $github_link/unblock.txt
        echo_RESULT $?

        rm -f /opt/bin/unblock_ipset.sh
        echo -en "$WGET -O /opt/bin/unblock_ipset.sh $github_link/unblock_ipset.sh...    "
        $WGET -O /opt/bin/unblock_ipset.sh $github_link/unblock_ipset.sh
        echo_RESULT $?
        chmod +x /opt/bin/unblock_ipset.sh

        rm -f /opt/bin/unblock_dnsmasq.sh
        echo -en "$WGET -O /opt/bin/unblock_dnsmasq.sh $github_link/unblock_dnsmasq.sh...    "
        $WGET -O /opt/bin/unblock_dnsmasq.sh $github_link/unblock_dnsmasq.sh
        echo_RESULT $?
        chmod +x /opt/bin/unblock_dnsmasq.sh

        /opt/bin/unblock_dnsmasq.sh
        echo_RESULT $?

        rm -f /opt/bin/update_dnsmasq.sh
        echo -en "$WGET -O /opt/bin/update_dnsmasq.sh $github_link/update_dnsmasq.sh...    "
        $WGET -O /opt/bin/update_dnsmasq.sh $github_link/update_dnsmasq.sh
        echo_RESULT $?
        chmod +x /opt/bin/update_dnsmasq.sh

#        rm -f /opt/etc/cron.daily/backup
#        echo -en "$WGET -O /opt/etc/cron.daily/backup $github_link/backup...    "
#        $WGET -O /opt/etc/cron.daily/backup $github_link/backup
#        echo_RESULT $?
#        chmod 600 /opt/etc/cron.daily/backup

        rm -f /opt/etc/init.d/S99unblock
        echo -en "$WGET -O /opt/etc/init.d/S99unblock $github_link/S99unblock...    "
        $WGET -O /opt/etc/init.d/S99unblock $github_link/S99unblock
        echo_RESULT $?
        chmod +x /opt/etc/init.d/S99unblock
        sed -i "s/hash:net/${set_type}/g" /opt/etc/init.d/S99unblock
        sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/init.d/S99unblock

        rm -f /opt/etc/ndm/netfilter.d/100-redirect.sh
        echo -en "$WGET -O /opt/etc/ndm/netfilter.d/100-redirect.sh $github_link/100-redirect.sh...    "
        $WGET -O /opt/etc/ndm/netfilter.d/100-redirect.sh $github_link/100-redirect.sh
        echo_RESULT $?
        chmod +x /opt/etc/ndm/netfilter.d/100-redirect.sh
        sed -i "s/hash:net/${set_type}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
        sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh

        rm -f /opt/etc/dnsmasq.conf
        echo -en "$WGET -O /opt/etc/dnsmasq.conf $github_link/dnsmasq.conf...    "
        $WGET -O /opt/etc/dnsmasq.conf $github_link/dnsmasq.conf
        echo_RESULT $?
        sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/dnsmasq.conf

        rm -f /opt/etc/hosts.dnsmasq
        echo -en "$WGET -O /opt/etc/hosts.dnsmasq $github_link/hosts.dnsmasq...    "
        $WGET -O /opt/etc/hosts.dnsmasq $github_link/hosts.dnsmasq
        echo_RESULT $?

        if [[ ! -d '/opt/etc/cron.d' ]]; then
            mkdir -p /opt/etc/cron.d
        fi
        echo -e "00 06 * * * root /opt/bin/unblock_ipset.sh\n" > /opt/etc/cron.d/ipsec
        chmod 600 /opt/etc/cron.d/ipsec

        # echo -e '#!/opt/bin/sh\n\nndmq -p "system reboot"' > /opt/etc/ndm/button.d/reboot.sh
        # chmod +x /opt/etc/ndm/button.d/reboot.sh

        rci_post '[{"opkg": {"dns-override": true}},{"system": {"configuration": {"save": true}}}]'
        confirm_reboot && rci_post '[{"system":{"reboot":true}}]'

        sleep 5
}


case "$1" in
    remove)
        case "$2" in
            dnscrypt)
                _remove_dnscrypt
            ;;
            kmod)
                _remove_kmod
            ;;
            *)
                _remove_base_environment
            ;;
        esac
    ;;
    install)
        case "$2" in
            dnscrypt)
                _install_dnscrypt
            ;;
            dnsmasq)
                _install_dnsmasq
            ;;
            kmod)
                _install_kmod
            ;;
            *)
                _install_base_environment
            ;;
        esac
    ;;
esac

if [[ "$DEBUG" -eq '1' ]]; then
    set +x
fi

exit 0
