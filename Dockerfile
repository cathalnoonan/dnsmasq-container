FROM alpine:3.23

RUN apk add --no-cache \
        bind-tools \
        dnsmasq \
        envsubst \
    && adduser -D -H -s /sbin/nologin dnsuser

# Work in /opt/dnsmasq dir so dnsuser won't need root
RUN mkdir -p /opt/dnsmasq/dnsmasq.conf.d/ \
    && chown -R dnsuser:dnsuser /opt/dnsmasq

USER dnsuser
ENV HEALTHCHECK_INTERNAL_DOMAIN_NAME=
ENV HEALTHCHECK_EXTERNAL_DOMAIN_NAME=google.com
WORKDIR /opt/dnsmasq/

# Copy configs
COPY --chown=dnsuser:dnsuser entrypoint.sh /entrypoint.sh
COPY --chown=dnsuser:dnsuser healthcheck.sh /healthcheck.sh

HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
    CMD /healthcheck.sh

EXPOSE 53/udp 53/tcp

CMD [ "/entrypoint.sh" ]
