# WordPress Bedrock - Docker Setup

High-performance Docker stack for Bedrock-based WordPress sites.

## Stack
- **PHP-FPM 8.3** (Alpine) with all WordPress extensions
- **NGINX** with FastCGI caching (Bedrock-aware routing)
- **MariaDB 11** with InnoDB tuning
- **Redis 7** for object caching
- **SSH** with AuthorizedKeysCommand for multi-developer access

## Included Tools
- Composer 2
- npm / Node.js
- WP-CLI
- MariaDB client

## How It Works

On first boot, the container checks for `vendor/` and runs `composer install` if missing. Your Bedrock codebase is mounted from the project root (the parent of this folder).

## Setup

1. Drop this `wordpress-bedrock/` folder into the root of your Bedrock project
2. In Dokploy, create a Compose service pointing at this repo
3. Set **Compose Path** to `wordpress-bedrock/docker-compose.yml`
4. Copy `.env.example` values into Dokploy's Environment tab
5. Generate salts at https://roots.io/salts.html and paste into env vars
6. Deploy
7. Assign domain in Dokploy's Domains tab (Service: `nginx`, Container Port: `80`)

## Project Structure

```
your-bedrock-project/
├── web/                  (served by NGINX)
│   ├── app/
│   └── wp/
├── config/
├── composer.json
└── wordpress-bedrock/    (this folder)
    ├── Dockerfile
    ├── docker-compose.yml
    └── nginx/
```

## SSH Access

Set `SSH_KEYS_URL` to a raw URL containing your team's public keys (one per line).

### Git Identity per Developer
Add env vars to each key line:
```
environment="GIT_AUTHOR_NAME=Jane Doe,GIT_AUTHOR_EMAIL=jane@example.com" ssh-rsa AAAA... jane@laptop
```

### Connect
```bash
ssh -p <mapped-port> root@<server-ip>
```

## Caching
- **OPcache**: PHP bytecode caching (always on)
- **FastCGI Cache**: NGINX page cache, bypassed for admin/logged-in users
- **Redis**: Object cache (install WP Redis plugin)

Check cache status via `X-FastCGI-Cache` header: `HIT`, `MISS`, or `BYPASS`.
