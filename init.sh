#!/bin/sh

touch /data/logs/mainlog /data/logs/rejectlog /data/logs/paniclog ; chown exim:exim /data/logs/mainlog /data/logs/rejectlog /data/logs/paniclog
touch /data/logs/procmailrc.log && chown vmail:vmail /data/logs/procmailrc.log && chmod 640 /data/logs/procmailrc.log

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

exim -bd -q5m
tail -f /data/logs/mainlog 
