# kamilpietka-devops

Infrastructure and deployment configuration for the public services hosted on the `kamilpietka.dev` VPS.

This repository is also part of my portfolio evidence for production engineering, Docker orchestration, reverse-proxy configuration, DNS/domain routing, system design, and operational practices.

## Hosted services

The VPS currently serves:

| Hostname | Purpose | Deployment |
|---|---|---|
| `kamilpietka.dev` | Engineering portfolio | Static files |
| `vouchers.kamilpietka.dev` | Vouchers frontend | Docker service |
| `api-vouchers.kamilpietka.dev` | Vouchers Laravel API | Docker service |
| `mojabiblioteka.kamilpietka.dev` | Moja Biblioteka public site | Static files |
| `mojabiblioteka.app` | Moja Biblioteka public site | Same static files |
| `www.mojabiblioteka.app` | Moja Biblioteka public site | Same static files |

The three Moja Biblioteka hostnames do **not** redirect between each other. Caddy serves all of them from the same `/srv/mojabiblioteka` directory.

## Deployment case study

[Read the production deployment case study](docs/production-case-study.md) — architecture, migration decisions, legacy build troubleshooting, Docker isolation, and observed validation.

## Architecture

```text
Internet
   |
   v
Cloudflare / DNS
   |
   v
VPS
   |
   v
Caddy :80 / :443
   |
   +-- kamilpietka.dev
   |      |
   |      +-- /srv/portfolio
   |
   +-- vouchers.kamilpietka.dev
   |      |
   |      +-- vouchers-frontend:80
   |
   +-- api-vouchers.kamilpietka.dev
   |      |
   |      +-- vouchers-nginx:80
   |
   +-- mojabiblioteka.kamilpietka.dev
   +-- mojabiblioteka.app
   +-- www.mojabiblioteka.app
          |
          +-- /srv/mojabiblioteka
```

## Network model

```text
Public Internet
      |
      | 80 / 443
      v
+------------------+
|      Caddy       |
| reverse proxy    |
| + static server  |
+------------------+
      |
      | Docker network: web
      |
      +-----------------------------+
      |                             |
      v                             v
vouchers-frontend:80        vouchers-nginx:80
                                      |
                                      v
                               vouchers-api:9000
                                      |
                                      v
                                vouchers-db:3306

Static mounts:
  /srv/portfolio
  /srv/mojabiblioteka
```

Only Caddy publishes HTTP and HTTPS ports to the host. The Vouchers frontend and API remain behind the internal Docker network.

## DNS

Expected DNS records point to the VPS:

```text
kamilpietka.dev                    -> VPS
vouchers.kamilpietka.dev           -> VPS
api-vouchers.kamilpietka.dev       -> VPS
mojabiblioteka.kamilpietka.dev     -> VPS
mojabiblioteka.app                 -> VPS
www.mojabiblioteka.app             -> VPS
```

Cloudflare may proxy these records.

## Public ports

The host should normally expose only:

```text
22/tcp   SSH
80/tcp   HTTP
443/tcp  HTTPS
```

Application ports, databases, Redis, PHP-FPM, and other internal services should not be exposed publicly.

## Repository structure

```text
kamilpietka-devops/
├── README.md
├── compose.yml
├── Caddyfile
├── .env.example
├── vouchers-api.env.example
├── .gitignore
│
├── site/
│   └── .gitkeep
│
├── mojabiblioteka/
│   └── .gitkeep
│
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   └── security.md
│
└── scripts/
    ├── deploy.sh
    └── health-check.sh
```

## Responsibilities

### Caddy

Caddy is the only public web entry point.

It is responsible for:

- HTTP/HTTPS termination
- domain-based routing
- serving the portfolio
- serving the Moja Biblioteka static site
- reverse proxying to Vouchers services

### Portfolio

`kamilpietka.dev` is served directly from:

```text
/srv/portfolio
```

The host directory is mounted from:

```text
./site
```

### Vouchers frontend

`vouchers.kamilpietka.dev` is reverse proxied to:

```text
vouchers-frontend:80
```

The frontend should use the production API URL:

```text
https://api-vouchers.kamilpietka.dev
```

### Vouchers API

`api-vouchers.kamilpietka.dev` is reverse proxied to:

```text
vouchers-nginx:80
```

Caddy proxies HTTP to `vouchers-nginx:80`; Nginx forwards PHP requests to `vouchers-api:9000`. The API uses private MySQL service `vouchers-db:3306` on the internal backend network. Laravel public files are copied from the API image into a shared volume by `vouchers-public-init`.

The Laravel production environment is stored separately in `vouchers-api.env`, which must not be committed.

### Moja Biblioteka

These hostnames all serve the same files:

```text
https://mojabiblioteka.kamilpietka.dev
https://mojabiblioteka.app
https://www.mojabiblioteka.app
```

Caddy maps each hostname to:

```text
/srv/mojabiblioteka
```

The host directory is mounted from:

```text
./mojabiblioteka
```

There is no separate `mojabiblioteka.app` application repository or deployment in this infrastructure design.

## First-time deployment

Clone the repository on the VPS:

```bash
git clone https://github.com/kamilloo/kamilpietka-devops.git
cd kamilpietka-devops
```

Create local production configuration:

```bash
cp .env.example .env
cp vouchers-api.env.example vouchers-api.env
```

Edit both files with the real production values.

Validate the Compose configuration:

```bash
docker compose config
```

Start the services:

```bash
docker compose pull
docker compose up -d
```

Check status:

```bash
docker compose ps
```

Then run:

```bash
./scripts/health-check.sh
```

## Deployment workflow

```text
Application repositories
        |
        | build images
        v
Container registry
        |
        v
kamilpietka-devops
        |
        | docker compose pull
        | docker compose up -d
        v
VPS
        |
        v
Caddy + Docker services
```

Static content can be deployed independently to `site/` and `mojabiblioteka/`.

See [`docs/deployment.md`](docs/deployment.md) for details.

## Security

Production secrets are not stored in Git.

Never commit:

- `.env`
- `vouchers-api.env`
- Laravel `APP_KEY`
- database passwords
- Cloudflare API credentials
- private SSH keys
- third-party API tokens

See [`docs/security.md`](docs/security.md).

## Portfolio evidence

This repository demonstrates practical production engineering:

- Docker Compose orchestration
- Caddy reverse proxying
- multi-domain routing
- shared static-site hosting
- separation between public and internal services
- environment and secret separation
- health checks
- repeatable deployment
- infrastructure documentation

The goal is simple:

> Skills are claims. Projects are proof.
