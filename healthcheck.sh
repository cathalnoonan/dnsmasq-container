#!/bin/sh

# Check UDP local resolution (authoritative)
dig @127.0.0.1 localhost +time=2 +tries=2 +short >/dev/null 2>&1 || exit 1

# Check TCP local resolution
dig +tcp @127.0.0.1 localhost +time=2 +tries=2 +short >/dev/null 2>&1 || exit 1

# Optionally check internal DNS resolution
if [ -n "$HEALTHCHECK_INTERNAL_DOMAIN_NAME" ]; then
    dig @127.0.0.1 "$HEALTHCHECK_INTERNAL_DOMAIN_NAME" +time=2 +tries=1 +short >/dev/null 2>&1 || exit 1
fi

# Optionally check external DNS resolution (e.g. google.com)
if [ -n "$HEALTHCHECK_EXTERNAL_DOMAIN_NAME" ]; then
    dig @127.0.0.1 "$HEALTHCHECK_EXTERNAL_DOMAIN_NAME" +time=2 +tries=1 +short >/dev/null 2>&1 || exit 1
fi

exit 0
