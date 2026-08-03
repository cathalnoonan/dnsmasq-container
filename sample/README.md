# Sample Templates

The example files contained in this folder are used by GitHub Actions to verify the resolver is working.

## Structure

- **`templates/dnsmasq.conf`**: Base `dnsmasq` configuration. (For a full reference, see the [upstream example configuration](https://github.com/imp/dnsmasq/blob/master/dnsmasq.conf.example)).
- **`templates/dnsmasq.conf.d/`**: Subdirectory for additional configuration files loaded dynamically via `conf-dir`:
  - **`a-records.conf`**: Sample `A` record definitions.
  - **`cname-records.conf`**: Sample `CNAME` record alias definitions.
