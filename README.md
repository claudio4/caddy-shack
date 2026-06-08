# Caddy Shack

Caddy Shack serves as an automated way to build and distribute my preferred flavor of Caddy. So no more manually tracking updates of caddy and its modules for me.

### Included Modules

- Standard Caddy Modules
- Cloudflare DNS (`github.com/caddy-dns/cloudflare`)
- Caddy OIDC (`github.com/relvacode/caddy-oidc`)

### Container Details

The container image is built from source and runs on top of `gcr.io/distroless/static-debian13:nonroot`. It executes as a non-root user (`uid 65532`) and contains no shell or core utilities.

Standard Caddy environment variables and volumes are configured:
- `XDG_CONFIG_HOME=/config`
- `XDG_DATA_HOME=/data`

While built with Podman in mind, the image should work in any OCI runtime like Docker or k8s.

### Automated Updates and Tags

This project relies on Dependabot to check daily for updates to the Caddy and plugins and the Docker base image. Dependabot pull requests are automatically merged, triggering a GitHub Actions workflow that builds and publishes a fresh image. So this distribution remains up-to-date with upstream security patches and features.

The published images are tagged according to the upstream Caddy version:
- `latest`: The most recent successful build.
- Major versions (e.g., `2`)
- Minor versions (e.g., `2.3`)
- Specific patch versions (e.g., `2.3.4`)

## Usage

This image functions like Caddy's official image . Mount the folder of your `Caddyfile` to `/etc/caddy` (mouting the file directly can cause issues with the reload command. Refer to Caddy's official image for more info) and your persistent data volumes.

**Podman Example:**
```shell
podman run -d \
  --name caddy \
  -p 80:80 \
  -p 443:443 \
  -v /path/to/caddyfile/folder:/etc/caddy:Z \
  -v caddy_data:/data:Z \
  -v caddy_config:/config:Z \
  ghcr.io/claudio4/caddy-shack:latest
```

For docker just change the command above from `podman` to `docker`.
