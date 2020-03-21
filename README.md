# Выборочный обход блокировок на маршрутизаторах Keenetic
Подробности читайте в статье "Выборочный обход блокировок на маршрутизаторах с прошивкой Padavan и Keenetic OS" — https://habr.com/ru/post/428992/. Обязательно прочитайте (хотя бы один раз) статью перед тем, как использовать метод автоматической установки, и сделайте необходимые настройки на маршрутизаторе.

## Нюансы
После установки роутер начинает перехватывать и направлять в dnsmasq все DNS запросы.
Интернет фильтр так же перестаёт работать, но есть возможность частично использовать его функционал.

## Автоматическая установка:
```shell script
opkg install wget ca-certificates
wget --no-check-certificate -O /opt/bin/unblock_keenetic.sh https://raw.githubusercontent.com/TeroBlaZe/unblock_keenetic/master/unblock_keenetic.sh
chmod +x /opt/bin/unblock_keenetic.sh
unblock_keenetic.sh
```

## Удаление:
```shell script
unblock_keenetic.sh remove
```

## Ручное обновление списка блокировок (например при добавлении)
```shell script
unblock_update.sh
```

## Использование DNS-over-HTTPS и DNS-over-TLS в интернет фильтре

Чтобы запросы шли через DOT/DOH интернет фильтра, необходимо изменить /etc/dnsmasq.conf указав адрес одного из прокси DNS серверов, выводимых командой:
```shell script
cat /tmp/ndnproxymain.stat
```
```shell script

DNS Servers

                      Ip   Port  R.Sent  A.Rcvd  NX.Rcvd  Med.Resp  Avg.Resp  Rank
               127.0.0.1  40302       0       0        0       0ms       0ms     5
               127.0.0.1  40303       0       0        0       0ms       0ms     4
               127.0.0.1  40300       0       0        0       0ms       0ms     4
               127.0.0.1  40301       0       0        0       0ms       0ms     4
               127.0.0.1  40508    3028    3028        0      64ms      64ms     4
```
В этом примере выбран вручную установленный DNS-over-HTTPS сервер 127.0.0.1:40508 указав в `dnsmasq.conf`:
```shell script
server=127.0.0.1#40508
```
При этом обязательно нужно убрать адреса `1.1.1.1` и `1.0.0.1`
