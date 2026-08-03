#!/bin/sh
set -e

CONTAINER_NAME="dnsmasq"
PROD_DOMAIN="prod.example.com"
PROD_IP="192.168.0.3"

export PROD_DOMAIN
export PROD_IP

cleanup() {
    echo "Cleaning up container..."
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "1. Building Docker image..."
docker build -t dnsmasq-container .
echo

echo "2. Cleaning up any existing container..."
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
echo

echo "3. Running container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --health-interval 1s \
    --health-start-period 0s \
    -p 1053:53/udp \
    -p 1053:53/tcp \
    -e PROD_DOMAIN \
    -e PROD_IP \
    -v "$(pwd)/sample/templates:/opt/dnsmasq/templates" \
    dnsmasq-container
echo

echo "4. Waiting for container to be healthy..."
for i in $(seq 1 15); do
    STATUS=$(docker inspect --format='{{json .State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || true)
    echo "Container health status ($i/15): $STATUS"
    if [ "$STATUS" = '"healthy"' ]; then
        break
    fi
    sleep 1
done
[ "$STATUS" = '"healthy"' ]
echo

echo "5. Checking A records (without variable substitution)..."
DEV_RESP=$(dig -p 1053 +tcp +short @127.0.0.1 dev.example.com)
echo "dev.example.com -> $DEV_RESP"
[ "$DEV_RESP" = "192.168.0.1" ]
echo

TEST_RESP=$(dig -p 1053 +tcp +short @127.0.0.1 test.example.com)
echo "test.example.com -> $TEST_RESP"
[ "$TEST_RESP" = "192.168.0.2" ]
echo

echo "6. Checking A records (with variable substitution)..."
PROD_RESP=$(dig -p 1053 +tcp +short @127.0.0.1 "$PROD_DOMAIN")
echo "$PROD_DOMAIN -> $PROD_RESP"
[ "$PROD_RESP" = "$PROD_IP" ]
echo

echo "7. Checking CNAME record (with variable substitution)..."
CNAME_RESP=$(dig -p 1053 +tcp +short @127.0.0.1 CNAME dummy.example.com)
echo "CNAME dummy.example.com -> $CNAME_RESP"
[ "$CNAME_RESP" = "${PROD_DOMAIN}." ]
echo

ALIAS_RESP=$(dig -p 1053 +tcp +short @127.0.0.1 dummy.example.com)
echo "dummy.example.com -> $ALIAS_RESP"
[ "$ALIAS_RESP" = "${PROD_DOMAIN}." ]
echo

TARGET_RESP=$(dig -p 1053 +tcp +short @127.0.0.1 "$ALIAS_RESP")
echo "$ALIAS_RESP -> $TARGET_RESP"
[ "$TARGET_RESP" = "$PROD_IP" ]
echo

echo "8. Checking Public DNS forwarding..."
PUBLIC_RESP=$(dig -p 1053 +tcp +short @127.0.0.1 github.com)
echo "github.com -> $PUBLIC_RESP"
[ -n "$PUBLIC_RESP" ]
echo

echo "All CI checks passed successfully!"
