# Architecture

## Overview

The VPS hosts the portfolio, Vouchers, and the public Moja Biblioteka website.

Caddy is the single public HTTP/HTTPS entry point.

```text
                         +----------------------+
                         |      Internet        |
                         +----------+-----------+
                                    |
                                    v
                         +----------------------+
                         |   Cloudflare / DNS   |
                         +----------+-----------+
                                    |
                                    v
                         +----------------------+
                         |        VPS           |
                         |      :80 / :443      |
                         +----------+-----------+
                                    |
                                    v
                         +----------------------+
                         |       Caddy          |
                         | proxy + static files |
                         +---+-----------+------+
                             |           |
          +------------------+           +-------------------+
          |                                                  |
          v                                                  v
+----------------------+                           +----------------------+
| Static sites         |                           | Docker network: web  |
+----------------------+                           +----------------------+
| /srv/portfolio       |                              |              |
| /srv/mojabiblioteka  |                              v              v
+----------------------+                         frontend:80      api:8000
```

## Host routing

```text
kamilpietka.dev
    |
    +--> /srv/portfolio


vouchers.kamilpietka.dev
    |
    +--> vouchers-frontend:3000


api-vouchers.kamilpietka.dev
    |
    +--> vouchers-api:8000


mojabiblioteka.kamilpietka.dev
mojabiblioteka.app
www.mojabiblioteka.app
    |
    +--> /srv/mojabiblioteka
```

## Moja Biblioteka domain model

The same static site is served under three hostnames:

```text
                 /--> mojabiblioteka.kamilpietka.dev
/srv/mojabiblioteka
                 +--> mojabiblioteka.app
                 \--> www.mojabiblioteka.app
```

There is no redirect between those hostnames in the current configuration.

There is also no separate deployment for `mojabiblioteka.app`; it is another hostname for the same deployed files.

## Service boundaries

### Caddy

Public-facing responsibilities:

- HTTPS
- host routing
- static file serving
- reverse proxying

### Vouchers frontend

Internal Docker service:

```text
vouchers-frontend:3000
```

It should communicate with the API through the public production URL:

```text
https://api-vouchers.kamilpietka.dev
```

### Vouchers API

Internal Docker service:

```text
vouchers-api:8000
```

It is not published directly on the host.

## Why this layout

This layout keeps the public attack surface small:

```text
Internet
   |
   +--> 80
   +--> 443

SSH administration
   |
   +--> 22
```

Internal application ports remain available only inside Docker networking.
