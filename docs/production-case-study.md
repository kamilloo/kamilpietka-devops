# Production deployment case study — kamilpietka.dev

> **Skills are claims. Projects are proof.**

## Problem

Publish a portfolio, an Ionic/Angular Vouchers web frontend, a Laravel API and the Moja Biblioteka landing page from one VPS, with HTTPS, isolated application services, repeatable deployments and multiple hostnames.

## Delivered architecture

```text
Public visitors
      |
Cloudflare DNS / proxy (for configured records)
      |
      | HTTPS
      v
VPS: Caddy (:80 / :443; only web service publishing host ports)
      |
      +-- kamilpietka.dev -------------------------> static /srv/portfolio
      |
      +-- vouchers.kamilpietka.dev ---------------> vouchers-frontend (Nginx :80)
      |
      +-- api-vouchers.kamilpietka.dev -----------> vouchers-nginx (:80)
      |                                                |
      |                                                v
      |                                          vouchers-api (PHP-FPM :9000)
      |                                                |
      |                                                v
      |                                          vouchers-db (MySQL :3306)
      |
      +-- mojabiblioteka.kamilpietka.dev ---------+
      +-- mojabiblioteka.app ---------------------+--> static /srv/mojabiblioteka
      +-- www.mojabiblioteka.app ------------------+
```

Caddy and public-facing Nginx services communicate on the `web` network. The backend network is marked `internal: true`; PHP-FPM and MySQL do not publish host ports. Database contents are stored in a named Docker volume.

## Key engineering decisions

| Decision | Reason |
| --- | --- |
| Single Caddy entry point | Centralized HTTPS, host routing, static delivery and reverse proxies |
| Containerized Ionic/Angular frontend | Serve the production build from Nginx rather than a development server |
| Separate Laravel Nginx and PHP-FPM services | Nginx speaks HTTP; PHP-FPM listens on port 9000 using FastCGI, not HTTP |
| Dedicated MySQL service | Keep the application database off the public interface and retain data in a persistent volume |
| Separate `web` and `backend` Docker networks | Restrict direct connectivity to internal application dependencies |
| Init service for public assets | Copy Laravel `public/` assets from the PHP image into a shared volume that Nginx can serve |
| Reused Caddy data/config volumes | Preserve existing Caddy state during migration from the prior Compose deployment |
| Shared Moja Biblioteka document root | Serve the same files on three domains without redirecting between them |
| Production secrets outside Git | Keep Laravel key and DB credentials in ignored VPS environment files |

## Deployment and validation

The application images were built and tested locally before deployment. Local integration covered Nginx → PHP-FPM → Laravel, a healthy MySQL container and database migrations. Images were published under the `kamilloo20` Docker Hub namespace.

On the VPS, deployment uses the infrastructure repository's Compose file, Caddyfile and private environment files. The old Caddy container was retained during cutover as a rollback option.

Useful operational commands:

```bash
docker compose config -q
docker compose pull
docker compose up -d
docker compose ps -a
docker compose exec vouchers-api php artisan migrate:status
./scripts/health-check.sh
```

The rollout was verified with HTTP 200 responses for the Vouchers frontend and API, and the deployed Compose stack showed running Caddy, frontend, API Nginx and PHP-FPM services, healthy MySQL and a successfully completed public-assets init container. Four domains initially passed the health script; DNS for the two `.app` hostnames was subsequently corrected and the domains were visited successfully. A later six-domain health-script run has not been captured in this case study.

## Challenges resolved

1. **Legacy Ionic build:** used Node 12/npm 6 for Angular 8/Ionic 4 and fixed duplicate Angular NgModule declarations.
2. **PHP runtime dependencies:** fixed a missing Alpine FreeType runtime library needed by the GD extension.
3. **Missing Composer package:** the historical `cnvs/studio` Git repository was inaccessible; the dependency was removed experimentally while preserving `cnvs/canvas`.
4. **Composer autoload order:** installed vendors before copying the app with `--no-autoloader`, then generated autoload files after the application directories were present.
5. **Container web boundary:** adjusted from a direct API HTTP assumption to Caddy → Nginx → PHP-FPM; corrected Nginx public-file mounts during local testing.
6. **Multi-domain DNS:** fixed resolution for `mojabiblioteka.app` and `www.mojabiblioteka.app`.

## Evidence

- [Docker Compose configuration](../compose.yml)
- [Caddy host routing](../Caddyfile)
- [Deployment instructions](deployment.md)
- [Health-check script](../scripts/health-check.sh)
- [Vouchers Laravel source](https://github.com/kamilloo/vouchers)
- [Vouchers Ionic frontend source](https://github.com/kamilloo/vouchers-app)

## Limitations and next steps

- PHP 7.2, Laravel 7.9.2 and MySQL 5.7 are unsupported legacy components; upgrade and security review are priorities.
- The Studio feature requires regression testing following the removal of `cnvs/studio`.
- HTTP 200 and container health do not prove every authenticated workflow or database-backed feature operates correctly.
- Automated database backups, CI/CD, monitoring and immutable image tags are recommended follow-up work.

**Scope of evidence:** this document records an observed deployment and troubleshooting process. It does not claim high availability, zero-downtime releases, automated rollback or a completed security audit.
