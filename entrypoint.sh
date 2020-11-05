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

cmd="/data/common_bin/dockerize-alpine"
if [ -x "$cmd" ]; then
  checks=""
  if [ -n "$WAITFOR" ]; then
    for CHECK in $WAITFOR; do
      checks="$checks -wait $CHECK"
    done
    $cmd $checks -timeout 180s -wait-retry-interval 15s
    [ $? -ne 0 ] && exit 1
  fi
fi

exec tail -f /data/logs/mainlog &
exec "$@"
