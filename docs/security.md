# Security

## Public ports

The expected host exposure is:

```text
22/tcp   SSH
80/tcp   HTTP
443/tcp  HTTPS
```

The Vouchers frontend and API do not publish their application ports directly to the host.

## Network boundary

```text
Internet
   |
   v
Caddy
   |
   +--> static mounts
   |
   +--> Docker network: web
            |
            +--> vouchers-frontend
            +--> vouchers-api
```

## SSH hardening

After verifying SSH key access for the deployment user:

- disable root SSH login
- disable password authentication
- use SSH keys
- keep the firewall enabled
- restrict SSH by source address where practical

## Secrets

Do not commit:

```text
.env
vouchers-api.env
APP_KEY
database passwords
API tokens
Cloudflare credentials
private keys
```

Production secrets should remain on the server or in a dedicated secret-management system.

## Application configuration

The Laravel API should use production settings such as:

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api-vouchers.kamilpietka.dev
FRONTEND_URL=https://vouchers.kamilpietka.dev
```

CORS should allow the actual frontend origin rather than a wildcard when credentials are involved.

## Docker

Recommended operational practices:

- keep Docker Engine updated
- prefer versioned application images
- avoid privileged containers
- remove unused images periodically
- monitor logs
- back up persistent application data

## TLS

Caddy handles HTTPS for all configured public hostnames.

DNS for each hostname must resolve correctly before certificate issuance can succeed.

## Static sites

Both static directories are mounted read-only into Caddy:

```text
./site:/srv/portfolio:ro
./mojabiblioteka:/srv/mojabiblioteka:ro
```

This prevents the web server container from modifying the deployed files.
