FROM alpine:3.9

LABEL maintainer="docker-dario@neomediatech.it"

RUN apk update; apk upgrade ; apk add --no-cache tzdata; cp /usr/share/zoneinfo/Europe/Rome /etc/localtime
RUN apk add --no-cache tini exim exim-cdb exim-dbmdb exim-dnsdb exim-scripts exim-utils bash redis procmail \
    && rm -rf /usr/local/share/doc /usr/local/share/man \ 
    && addgroup -g 5000 vmail \
    && adduser -D -u 5000 -G vmail vmail \
    && mkdir -p /var/spool/mail \
    && touch /var/spool/mail/vmail \
    && chown vmail:vmail /var/spool/mail/vmail

COPY conf/* /etc/exim/
COPY conf.d /etc/exim/conf.d
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 25 465 587

# ToDO: more useful check, like a whole transaction
HEALTHCHECK --interval=30s --timeout=30s --start-period=10s --retries=20 CMD nc -w 7 -zv 0.0.0.0 25
      
ENTRYPOINT ["/entrypoint.sh"]
CMD ["tini","--","exim","-bd","-q5m"]
