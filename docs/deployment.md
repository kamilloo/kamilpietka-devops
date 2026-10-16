# Deployment

## Server location

Recommended deployment directory:

```text
/opt/kamilpietka-devops
```

Example:

```text
/opt/kamilpietka-devops/
├── compose.yml
├── Caddyfile
├── .env
├── vouchers-api.env
├── site/
├── mojabiblioteka/
├── docs/
└── scripts/
```

## DNS prerequisites

The following hostnames should resolve to the VPS:

```text
kamilpietka.dev
vouchers.kamilpietka.dev
api-vouchers.kamilpietka.dev
mojabiblioteka.kamilpietka.dev
mojabiblioteka.app
www.mojabiblioteka.app
```

## Initial setup

```bash
git clone https://github.com/kamilloo/kamilpietka-devops.git
cd kamilpietka-devops

cp .env.example .env
cp vouchers-api.env.example vouchers-api.env
```

Configure the real image names and secrets.

Validate:

```bash
docker compose config
```

Pull application images:

```bash
docker compose pull
```

Start:

```bash
docker compose up -d
```

Check:

```bash
docker compose ps
```

## Deploy portfolio files

The portfolio is mounted from:

```text
./site
```

Example from a development machine:

```bash
rsync -avz --delete \
  --exclude '.git' \
  --exclude '.github' \
  --exclude 'README.md' \
  ./ \
  deploy@SERVER:/opt/kamilpietka-devops/site/
```

## Deploy Moja Biblioteka static site

The same static content serves:

```text
mojabiblioteka.kamilpietka.dev
mojabiblioteka.app
www.mojabiblioteka.app
```

Files are mounted from:

```text
./mojabiblioteka
```

Example:

```bash
rsync -avz --delete \
  ./ \
  deploy@SERVER:/opt/kamilpietka-devops/mojabiblioteka/
```

## Update Vouchers

Update image tags in `.env` if necessary, then:

```bash
docker compose pull
docker compose up -d --remove-orphans
```

Inspect logs:

```bash
docker compose logs --tail=100 caddy
docker compose logs --tail=100 vouchers-frontend
docker compose logs --tail=100 vouchers-api
```

Run health checks:

```bash
./scripts/health-check.sh
```

## Rollback

Prefer immutable image tags.

Example:

```env
VOUCHERS_FRONTEND_IMAGE=ghcr.io/kamilloo/vouchers-app:2026-10-16
VOUCHERS_API_IMAGE=ghcr.io/kamilloo/vouchers:2026-10-16
```

To roll back:

1. restore the previous image tags;
2. pull the old images;
3. recreate the services.

```bash
docker compose pull
docker compose up -d
```

## Validate Caddy

To validate the active Caddy configuration through the container:

```bash
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
```

After editing `Caddyfile`, restart or reload Caddy:

```bash
docker compose restart caddy
```
