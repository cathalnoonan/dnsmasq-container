FROM alpine:3.23

RUN apk add --no-cache \
        bind-tools \
        dnsmasq \
        envsubst \
    && adduser -D -H -s /sbin/nologin dnsuser

ENV DNSMASQ_ROOT_DIRECTORY=/opt/dnsmasq
ENV DNSMASQ_TEMPLATE_DIRECTORY=${DNSMASQ_ROOT_DIRECTORY}/templates

# Work in ${DNSMASQ_ROOT_DIRECTORY} dir so dnsuser won't need root
RUN mkdir -p ${DNSMASQ_ROOT_DIRECTORY}/dnsmasq.conf.d/ \
    && chown -R dnsuser:dnsuser ${DNSMASQ_ROOT_DIRECTORY}

USER dnsuser

ENV HEALTHCHECK_INTERNAL_DOMAIN_NAME=
ENV HEALTHCHECK_EXTERNAL_DOMAIN_NAME=google.com
ENV UPSTREAM_DNS_1=8.8.8.8
ENV UPSTREAM_DNS_2=1.1.1.1

WORKDIR ${DNSMASQ_ROOT_DIRECTORY}

# Copy configs
COPY --chown=dnsuser:dnsuser entrypoint.sh /entrypoint.sh
COPY --chown=dnsuser:dnsuser healthcheck.sh /healthcheck.sh

HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
    CMD /healthcheck.sh

EXPOSE 53/udp 53/tcp

CMD [ "/entrypoint.sh" ]
