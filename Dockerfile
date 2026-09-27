FROM blindlight/uuplugin@sha256:89f39c6336ebf9ef1c8830786cc60cc6c69c99cc8e8e381a3ec9c7967516ac4f

LABEL org.opencontainers.image.source="https://github.com/landuo/uuplugin" \
      org.opencontainers.image.description="UU router plugin container with current installer and LAN forwarding"

COPY uu_prepare /etc/init.d/uu_prepare
COPY healthcheck.sh /usr/local/bin/uu-healthcheck
COPY LICENSE NOTICE.md /usr/share/licenses/uuplugin/

RUN chmod 755 /etc/init.d/uu_prepare /usr/local/bin/uu-healthcheck \
    && /etc/init.d/uu_prepare enable

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD ["/usr/local/bin/uu-healthcheck"]
