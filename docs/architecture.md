# Architecture

See the [production deployment case study](production-case-study.md) for the verified rollout, decisions, evidence and limitations.

## Runtime topology

```text
Internet / Cloudflare
        |
        v
Caddy :80 / :443 (only public-facing web service)
        |
        +--> kamilpietka.dev --------------------> /srv/portfolio
        +--> vouchers.kamilpietka.dev -----------> vouchers-frontend:80
        +--> api-vouchers.kamilpietka.dev -------> vouchers-nginx:80
        |                                              |
        |                                              v
        |                                       vouchers-api:9000
        |                                         (PHP-FPM)
        |                                              |
        |                                              v
        |                                       vouchers-db:3306
        |                                         (MySQL)
        +--> mojabiblioteka.kamilpietka.dev ---+
        +--> mojabiblioteka.app ----------------+--> /srv/mojabiblioteka
        +--> www.mojabiblioteka.app ------------+
```

## Networks and volumes

- `web`: Caddy, Vouchers frontend and API Nginx.
- `backend` (`internal: true`): API Nginx, PHP-FPM and MySQL.
- `vouchers_db`: persistent MySQL data.
- `vouchers_public`: Laravel public assets, copied from the API image using the one-shot `vouchers-public-init` service and mounted read-only into API Nginx.
- `portfolio_caddy_data` and `portfolio_caddy_config`: existing Caddy volumes reused during migration.

Only Caddy publishes ports 80 and 443. SSH port 22 is handled by the host. PHP-FPM and MySQL have no published host ports.

## Host routing

The three Moja Biblioteka hostnames serve the same static directory with no redirects between them. Caddy terminates HTTPS and proxies the Vouchers frontend and Laravel Nginx service by hostname.

## Limitations

The deployment uses unsupported PHP 7.2, Laravel 7.9.2 and MySQL 5.7. The architecture reduces direct port exposure, but does not substitute for runtime upgrades, backups, monitoring and security review.
