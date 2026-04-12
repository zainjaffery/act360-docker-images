# WordPress Standard - Docker Setup

High-performance WordPress container stack for Dokploy.

## Stack
- **PHP-FPM 8.3** (Alpine) with all WordPress extensions baked in
- **NGINX** with FastCGI caching
- **MariaDB 11** with InnoDB tuning
- **Redis 7** for object caching
- **SSH** with AuthorizedKeysCommand for multi-developer access

## Included Tools
- Composer 2
- npm / Node.js
- WP-CLI
- MariaDB client (for CLI access)

## Quick Start

1. Copy `.env.example` to `.env` and update credentials
2. In Dokploy: Create Compose service, point to this repo
3. Set environment variables in Dokploy's Environment tab
4. Deploy
5. Assign domain in Dokploy's Domains tab (Container Port: 80, Service: nginx)
6. Complete WordPress install wizard at your domain

## SSH Access

Set `SSH_KEYS_URL` to a raw URL containing your team's public keys (one per line).
Example: `https://raw.githubusercontent.com/yourorg/ssh-keys/main/authorized_keys`

### Git Identity per Developer
Add environment variables to each key line in the keys file:
```
environment="GIT_AUTHOR_NAME=Jane Doe,GIT_AUTHOR_EMAIL=jane@example.com" ssh-rsa AAAA... jane@laptop
```

### Connect via Cursor/VS Code
```bash
ssh -p <mapped-port> root@<server-ip>
```

## Database Access

MariaDB is accessible from within the Docker network at `db:3306`.

For external access, use SSH tunnel:
```bash
ssh -p <ssh-port> -L 3306:db:3306 root@<server-ip>
```
Then connect MySQL Workbench to `localhost:3306`.

## Caching

- **OPcache**: PHP bytecode caching (enabled by default)
- **FastCGI Cache**: NGINX serves cached pages without hitting PHP
- **Redis**: WordPress object cache (install Redis Object Cache plugin and enable)

Cache is automatically bypassed for logged-in users, POST requests, admin pages, cart/checkout (WooCommerce).

Check cache status via the `X-FastCGI-Cache` response header:
- `HIT` = served from cache
- `MISS` = generated fresh
- `BYPASS` = skipped cache (logged-in, admin, etc.)
