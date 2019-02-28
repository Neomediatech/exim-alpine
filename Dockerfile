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
COPY init.sh /
RUN chmod +x /init.sh

EXPOSE 25 465 587

ENTRYPOINT ["tini", "--", "/init.sh"]
