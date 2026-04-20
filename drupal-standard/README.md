# Drupal Standard - Docker Setup

High-performance Docker stack for Composer-managed Drupal sites (D8/9/10/11).

## Stack
- **PHP-FPM 8.3** (Alpine) with all Drupal extensions
- **NGINX** with FastCGI caching (Drupal-aware routing)
- **MariaDB 11** with InnoDB tuning
- **Redis 7** for object caching
- **SSH** with AuthorizedKeysCommand for multi-developer access

## Included Tools
- Composer 2
- Drush launcher
- npm / Node.js
- MariaDB client

## Setup

1. Drop the `system/` folder (containing these files) into your Drupal project root
2. In Dokploy, create a Compose service pointing at your repo
3. Set **Compose Path** to `system/docker-compose.yml`
4. Copy `.env.example` values into Dokploy's Environment tab
5. Deploy
6. Assign domain in Dokploy's Domains tab (Service: `nginx`, Container Port: `80`)

## Project Structure

```
your-drupal-project/
├── composer.json
├── composer.lock
├── vendor/
├── web/                    (served by NGINX)
│   ├── core/
│   ├── modules/
│   ├── themes/
│   ├── sites/
│   │   └── default/
│   │       ├── files/      (persistent volume)
│   │       └── settings.php
│   └── index.php
├── config/
│   └── sync/
└── system/                 (this folder)
    ├── Dockerfile
    ├── docker-compose.yml
    └── nginx/
```

## SSH Access

Set `SSH_KEYS_URL` to a raw URL containing your team's public keys (one per line).

### Connect
```bash
ssh -p <SSH_PORT> root@<server-ip>
```

## Database Access

Via SSH tunnel:
```bash
ssh -L 3306:db:3306 <site-name>
```
Then connect MySQL Workbench to `localhost:3306`.

## Caching
- **OPcache**: PHP bytecode caching (always on)
- **FastCGI Cache**: NGINX page cache, bypassed for admin/logged-in users
- **Redis**: Object cache (install Drupal Redis module and configure)

Check cache status via `X-FastCGI-Cache` header: `HIT`, `MISS`, or `BYPASS`.

## Redis Setup

1. `composer require drupal/redis`
2. Enable the module: `drush en redis`
3. Add to `settings.php`:
```php
$settings['redis.connection']['host'] = 'redis';
$settings['redis.connection']['port'] = 6379;
$settings['cache']['default'] = 'cache.backend.redis';
```
