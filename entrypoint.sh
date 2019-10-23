#!/bin/bash

mkdir -p /data/logs/
touch /data/logs/mainlog /data/logs/rejectlog /data/logs/paniclog ; chown exim:exim /data/logs/mainlog /data/logs/rejectlog /data/logs/paniclog

if [ -f /servername_cert ]; then
  servername_cert="$(grep "^[[:alnum:]]" /servername_cert|head -n1|tr -d " ")"
  if [ -n "$servername_cert" ]; then
    sed -i "s/^SERVER_CERT.*$/SERVER_CERT=$servername_cert/" /etc/exim/exim.conf
    if [ -d /data/certs/archive/$servername_cert ]; then
	    chmod 644 /data/certs/archive/$servername_cert/privkey*.pem
    fi
  fi
fi

if [ -d /data/certs/archive ]; then
	chmod 755 /data/certs/archive
fi

if [ -f /etc/exim/conf.d/hubbed_hosts ]; then
	cp /etc/exim/conf.d/hubbed_hosts /etc/exim/hubbed_hosts
fi

# Variable WAITFOR set as a space separated series of comma separated values
# i.e.: "my_clamav:clamav:3310
# 3rd parameter (port) can be omitted for default ports
check_service() {
  until eval $1 ; do
    sleep 1
    echo -n "..."
  done
  echo -n "OK"
}
if [ -n "$WAITFOR" ]; then
  for CHECK in $WAITFOR; do
    IFS=':' read -a SERVICE <<< "$CHECK"
    # while array: ${SERVICE[*]}
    NAME="${SERVICE[0]}"
    SRV="${SERVICE[1]}"
    PORT="${SERVICE[2]}"
    if [ -z "$NAME" -o -z "$SRV" ]; then
      continue
    fi
    echo -n "Checking for service $SRV on $NAME..."
    case "$SRV" in
      "clamav")
        PORT=${PORT:-3310}
        check_service 'echo PING | nc -w 5 $NAME $PORT 2>/dev/null'
        ;;
      "rspamd")
        check_service 'ping -c1 $NAME 1>/dev/null 2>/dev/null'
        ;;
      "redis")
        PORT=${PORT:-6379}
        check_service 'timeout -t 2 redis-cli -h $NAME -p $PORT PING'
        ;;
      *)
        check_service 'ping -c1 $NAME 1>/dev/null 2>/dev/null'
        ;;
    esac
    echo " "
  done
fi

# exec exim -bd -q5m
exec tail -f /data/logs/mainlog &
exec "$@"
