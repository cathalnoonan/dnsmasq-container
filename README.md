# DNSMasq Container

> **Note:** This repository is an example reference rather than a ready-to-use repository. Please read through the README and adapt the example setup on your side to fit your specific needs.

A lightweight Docker container for running **dnsmasq** with dynamic environment variable substitution (`envsubst`) on startup.

## Features

- **Lightweight**: Built on Alpine Linux.
- **Non-Root Execution**: Runs as an unprivileged user (`dnsuser`).
- **Dynamic Templating**: Automatically processes `.conf` files through `envsubst` at container launch.
- **Health Checks**: Built-in health check script verifying UDP, TCP, internal records, and external DNS forwarding.

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/cathalnoonan/dnsmasq-container.git
# git clone git@github.com:cathalnoonan/dnsmasq-container.git

cd dnsmasq-container
```

### 2. Build the Docker Image

Build the container image locally:

```bash
docker build -t dnsmasq-container .
```

### 3. Run the Container

Mount your configuration templates into `/opt/dnsmasq/templates`:

> Note: The files in `samples/templates` serve as an example, you will likely want to adapt them for your own needs.

```bash
docker run -d \
  --name dnsmasq \
  -p 53:53/udp \
  -p 53:53/tcp \
  -v $(pwd)/sample/templates:/opt/dnsmasq/templates \
  dnsmasq-container
```

---

## Configuration

### Environment Variables

| Variable | Default Value | Description |
|---|---|---|
| `TEMPLATE_ROOT` | `/opt/dnsmasq/templates` | Path to template directory containing `.conf` files to process. |
| `DESTINATION_ROOT` | `/opt/dnsmasq` | Path where rendered configuration files will be written. |
| `HEALTHCHECK_INTERNAL_DOMAIN_NAME` | *(empty)* | Optional domain name to verify internal DNS record resolution during health checks. |
| `HEALTHCHECK_EXTERNAL_DOMAIN_NAME` | `google.com` | Set to any domain (e.g. `google.com`) to verify external domain resolution during health checks, or leave empty to opt-out. |

### Environment Variable Substitution (`envsubst`)

Any `.conf` files in `$TEMPLATE_ROOT` (including subdirectories such as `dnsmasq.conf.d/`) are processed with `envsubst` during container startup.

For example, if your template file contains:

```conf
address=/${MY_DOMAIN}/${MY_IP}
```

You can supply values at runtime:

```bash
docker run -d \
  --name dnsmasq \
  -p 53:53/udp -p 53:53/tcp \
  -e MY_DOMAIN="internal.dev" \
  -e MY_IP="10.0.0.50" \
  -v $(pwd)/sample/templates:/opt/dnsmasq/templates \
  dnsmasq-container
```

---

## Directory Structure & Sample Templates

A reference configuration layout is provided in the [`sample`](./sample/) directory:

```text
sample/templates/
├── dnsmasq.conf
└── dnsmasq.conf.d/
    ├── a-records.conf
    └── cname-records.conf
```

> **Important:** The contents of the `sample/` folder are **not built into the container image**. These files (or ideally your own custom configuration files) must be provided at runtime by mounting them into `/opt/dnsmasq/templates`.

---

## Health Check

The container includes a built-in health check (`/healthcheck.sh`) running every 15 seconds:

- Verifies local UDP DNS resolution (`dig @127.0.0.1 localhost`).
- Verifies local TCP DNS resolution (`dig +tcp @127.0.0.1 localhost`).
- Optionally verifies internal domain resolution if `HEALTHCHECK_INTERNAL_DOMAIN_NAME` is configured.
- Optionally verifies external domain resolution if `HEALTHCHECK_EXTERNAL_DOMAIN_NAME` is configured.

> **Note:** Set `HEALTHCHECK_INTERNAL_DOMAIN_NAME` or `HEALTHCHECK_EXTERNAL_DOMAIN_NAME` to any target domain to check whether internal or external domain resolution is working, or leave them set to an empty string (`""`) to opt-out of those checks.

---

## Testing Resolution

Once the container is running, test DNS queries directly:

```bash
# Query A record
dig @127.0.0.1 dev.example.com

# Query CNAME record
dig @127.0.0.1 site.your.domain
```
