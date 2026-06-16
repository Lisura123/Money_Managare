# Deployment Guide — CLK Money Manager

## Server Details

| Item | Value |
|------|-------|
| VPS Provider | Hostinger |
| IP | `72.62.72.186` |
| OS | Ubuntu 25.10 |
| SSH | `ssh root@72.62.72.186` |

## Domains

| Service | Domain | Server Path |
|---------|--------|-------------|
| Laravel API | `https://money.cameralkstore.com` | `/var/www/money-api` |
| Staff Web (React) | `https://moneymanager.cameralkstore.com` | `/var/www/money-staff` |

## DNS Records

| Type | Name | Content |
|------|------|---------|
| A | `money` | `72.62.72.186` |
| A | `moneymanager` | `72.62.72.186` |

## Server Stack

| Software | Version |
|----------|---------|
| Nginx | 1.28.0 |
| PHP-FPM | 8.4.11 |
| MySQL | 8.4.7 |
| Node.js | 20.19.6 |
| Composer | 2.9.2 |
| Certbot (SSL) | Let's Encrypt, auto-renews |

## Database

| Setting | Value |
|---------|-------|
| Database | `money_manager` |
| User | `money_app` |
| Password | `M0n3yM@nag3r_2026!` |
| Host | `127.0.0.1` |

---

## Deploying Backend Updates

From your local machine:

```bash
# 1. Upload changed files (excludes vendor, .env, logs)
cd "/Users/lisura/Desktop/Money Manager"
rsync -avz --exclude='vendor' --exclude='node_modules' --exclude='.env' --exclude='storage/logs/*.log' backend/ root@72.62.72.186:/var/www/money-api/

# 2. SSH in and run post-deploy steps
ssh root@72.62.72.186

cd /var/www/money-api
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
chown -R www-data:www-data storage bootstrap/cache
```

### If you only changed code (no new packages or migrations):

```bash
rsync -avz --exclude='vendor' --exclude='node_modules' --exclude='.env' --exclude='storage/logs/*.log' backend/ root@72.62.72.186:/var/www/money-api/

ssh root@72.62.72.186 "cd /var/www/money-api && php artisan config:cache && php artisan route:cache && php artisan view:cache"
```

---

## Deploying Staff-Web Updates

From your local machine:

```bash
# 1. Build with production API URL
cd "/Users/lisura/Desktop/Money Manager/staff-web"
VITE_API_BASE_URL=https://money.cameralkstore.com/api npm run build

# 2. Upload built files
rsync -avz dist/ root@72.62.72.186:/var/www/money-staff/
```

---

## Building Flutter App for Production

The Flutter app uses `--dart-define=ENV=production` to switch to the production API URL.

```bash
# iOS (App Store)
cd "/Users/lisura/Desktop/Money Manager/frontend"
flutter build ipa --dart-define=ENV=production

# Android (APK)
flutter build apk --release --dart-define=ENV=production

# Android (App Bundle for Play Store)
flutter build appbundle --dart-define=ENV=production
```

The production URL is configured in `frontend/lib/config/app_config.dart`:
```
https://money.cameralkstore.com/api
```

For local development (default), it uses `http://localhost:8000/api`.

---

## Nginx Configs

| File | Domain |
|------|--------|
| `/etc/nginx/sites-available/money-api` | money.cameralkstore.com |
| `/etc/nginx/sites-available/money-staff` | moneymanager.cameralkstore.com |

After editing Nginx configs:
```bash
nginx -t && systemctl reload nginx
```

---

## SSL Certificates

Managed by Certbot (Let's Encrypt). Auto-renews via systemd timer.

```bash
# Check renewal status
certbot certificates

# Manual renewal (if needed)
certbot renew
```

---

## Useful Commands

```bash
# Check backend logs
ssh root@72.62.72.186 "tail -50 /var/www/money-api/storage/logs/laravel.log"

# Check Nginx error logs
ssh root@72.62.72.186 "tail -50 /var/log/nginx/error.log"

# Restart services
ssh root@72.62.72.186 "systemctl restart nginx php8.4-fpm"

# Clear all Laravel caches
ssh root@72.62.72.186 "cd /var/www/money-api && php artisan optimize:clear"

# Run database migrations
ssh root@72.62.72.186 "cd /var/www/money-api && php artisan migrate --force"

# Import a fresh database dump
scp /Users/lisura/Downloads/money_manager.sql root@72.62.72.186:/tmp/
ssh root@72.62.72.186 "mysql money_manager < /tmp/money_manager.sql"
```

---

## Quick One-Liner: Full Redeploy

### Backend
```bash
cd "/Users/lisura/Desktop/Money Manager" && rsync -avz --exclude='vendor' --exclude='node_modules' --exclude='.env' --exclude='storage/logs/*.log' backend/ root@72.62.72.186:/var/www/money-api/ && ssh root@72.62.72.186 "cd /var/www/money-api && composer install --no-dev --optimize-autoloader && php artisan migrate --force && php artisan config:cache && php artisan route:cache && php artisan view:cache && chown -R www-data:www-data storage bootstrap/cache"
```

### Staff-Web
```bash
cd "/Users/lisura/Desktop/Money Manager/staff-web" && VITE_API_BASE_URL=https://money.cameralkstore.com/api npm run build && rsync -avz dist/ root@72.62.72.186:/var/www/money-staff/
```
The admin account email - admin@admin.com, password - Test1234!

personal access token (classic) - [REDACTED]