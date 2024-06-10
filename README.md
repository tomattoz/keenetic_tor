# Выборочный проброс запросов к сайтам через TOR на маршрутизаторах Keenetic

## Предоставляется AS-IS, может содержать баги, но железо испортить не должно.
## Перед установкой ОБЯЗАТЕЛЬНО сделать бэкап настроек/прошивки

Ещё немного доработанная и сильно очищенная версия оригинального скрипта.
- вызовы через ndmq заменены на rci, т.к. ndmq - deprecated, а в aarch64 роутерах его вообще нет.
- добавлена поддержка obfs4 bridge
- добавлена поддержка зоны onion
- рабочая директория tor на ram-диске

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
/opt/bin/configure_keenetic.sh install
```

## Удаление:
```shell script
/opt/bin/configure_keenetic.sh remove
```

## Проброс адреса через TOR
1. Добавить адрес в unblock.txt `mcedit /opt/etc/unblock.txt`
1. Выполнить `bash /opt/bin/update_dnsmasq.sh`

## Настройка и обновление obfs4 bridge
1. Получить адреса на [сайте](https://bridges.torproject.org/bridges?transport=obfs4)
1. Прописать в конфиг `mcedit /opt/etc/tor/torrc` (в начале строки должно быть `Bridge `)
1. Перезапустить TOR `/opt/etc/init.d/S35tor restart`

## Возможные проблемы
- Если не открываются сайты, но https://check.torproject.org открывается, значит вероятнее всего не работает dnsmasq
- Если обратная ситуация и открываются все сайты кроме добавленных в unblock.txt, значит не работает tor
- Если ничего не открывается, нужно убедиться, что проблема не с DNS


## Полезные команды
- `netstat -anp | grep LISTEN` - Посмотреть на каких портах запущенны службы
- `cat /tmp/ndnproxymain.stat` - Доступные DNS серверы. Если пусто, то будут проблемы с резолвом доменов внутри роутера
- `/opt/etc/init.d/S56dnsmasq restart` - Перезапуск dnsmasq
- `/opt/etc/init.d/S35tor restart` - Перезапуск tor
