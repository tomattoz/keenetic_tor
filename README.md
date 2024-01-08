# Выборочный обход блокировок на маршрутизаторах Keenetic
Ещё немного доработанная и очищенная версия оригинального скрипта.
Также вызовы через ndmq заменены на rci, т.к. ndmq - deprecated, а в aarch64 роутерах его вообще нет.

## Нюансы
- После установки скрипта, отключается встроенный в роутер интернет-фильтр. Все запросы обрабатываются в dnsmasq, даже если в настройках
адаптера в ОС был указан какой-то другой адрес.
- В "Серверы DNS" необходимо указать любой DNS адрес или использовать адреса провайдера, если ничего не указать.

## Автоматическая установка:
```shell script
opkg update
opkg install bash wget-ssl ca-certificates
wget --no-check-certificate -O /opt/bin/configure_keenetic.sh https://raw.githubusercontent.com/PsychodelEKS/keenetic_tor/master/configure_keenetic.sh
chmod +x /opt/bin/configure_keenetic.sh
configure_keenetic.sh install
```

## Удаление:
```shell script
configure_keenetic.sh remove
```

## Разблокировка адреса
1. Добавить адрес в unblock.txt `mcedit /opt/etc/unblock.txt`
2. Выполнить `update_dnsmasq.sh`

## Возможные проблемы
- Если не открываются сайты, но https://check.torproject.org открывается, значит вероятнее всего не работает dnsmasq
- Если обратная ситуация и открываются все сайты кроме добавленных в unblock.txt, значит не работает tor
- Если ничего не открывается, нужно убедиться, что проблема не с днс


## Полезные команды

- `netstat -anp | grep LISTEN` - Посмотреть на каких портах запущенны службы
- `cat /tmp/ndnproxymain.stat` - Доступные DNS серверы. Если пусто, то будут проблемы с резолвом доменов внутри роутера. См. "Нюансы"
- `/opt/etc/init.d/S56dnsmasq restart` - Перезапуск dnsmasq
- `/opt/etc/init.d/S35tor restart` - Перезапуск tor
