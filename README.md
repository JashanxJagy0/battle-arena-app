# battle-arena-app
Ludo PvP + Free Fire tournament betting app with crypto wallet

## Project Structure

```
battle-arena-app/
├── backend/          # Node.js/Express API (TypeScript)
├── admin_panel/      # React 18 + Vite admin dashboard
├── flutter_app/      # Flutter mobile app
├── nginx/            # Reverse proxy configuration
├── docker-compose.yml          # Development compose
└── docker-compose.prod.yml     # Production compose
```

## CI/CD Pipelines

GitHub Actions workflows are located in `.github/workflows/`:

- **`ci.yml`** – Runs on every push/PR to `main`: lints and builds the backend and admin panel, and analyzes the Flutter app.
- **`deploy.yml`** – Runs on push to `main`: builds Docker images, pushes to GitHub Container Registry (GHCR), and deploys to a DigitalOcean droplet via SSH.

### Required GitHub Secrets

Configure the following secrets in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `DIGITALOCEAN_SSH_KEY` | Private SSH key for the droplet |
| `DIGITALOCEAN_HOST` | Droplet IP or hostname |
| `DIGITALOCEAN_USERNAME` | SSH username (e.g. `root`) |
| `GHCR_TOKEN` | GitHub personal access token with `write:packages` scope |
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Redis connection string |
| `JWT_SECRET` | Secret used to sign JWT tokens |
| `NOWPAYMENTS_API_KEY` | NOWPayments API key for crypto payments |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase service account JSON (as a string) |

## Production Deployment Guide

### 1. Provision a DigitalOcean Droplet

- Ubuntu 22.04, **2 GB RAM** minimum (4 GB recommended)
- Add your SSH public key during creation

### 2. Install Docker and Docker Compose

```bash
# On the droplet
curl -fsSL https://get.docker.com | sh
apt-get install -y docker-compose-plugin
```

### 3. Clone the Repository

```bash
mkdir -p /opt/battle-arena && cd /opt/battle-arena
git clone https://github.com/<your-org>/battle-arena-app.git .
```

### 4. Set Environment Variables

Create `/opt/battle-arena/.env`:

```env
GITHUB_REPOSITORY_OWNER=<your-github-org>
POSTGRES_PASSWORD=<strong-password>
POSTGRES_DB=battle_arena
DATABASE_URL=postgresql://postgres:<strong-password>@postgres:5432/battle_arena
REDIS_URL=redis://redis:6379
JWT_SECRET=<random-secret>
NOWPAYMENTS_API_KEY=<key>
FIREBASE_SERVICE_ACCOUNT=<json-string>
```

### 5. Update Domain Names

Replace `yourdomain.com` in `nginx/nginx.conf` with your actual domain.

### 6. Start Services

```bash
cd /opt/battle-arena
docker compose -f docker-compose.prod.yml up -d
```

### 7. Set Up SSL with Certbot

```bash
# Install Certbot
apt-get install -y certbot

# Obtain certificates (HTTP-01 challenge via the nginx container)
certbot certonly --webroot \
  -w /var/lib/docker/volumes/battle-arena-app_certbot_www/_data \
  -d api.yourdomain.com \
  -d admin.yourdomain.com

# Reload nginx to pick up the certificates
docker compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

Add a cron job to auto-renew:

```bash
(crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --quiet && docker compose -f /opt/battle-arena/docker-compose.prod.yml exec nginx nginx -s reload") | crontab -
```

### 8. Verify Deployment

```bash
# Check all containers are running
docker compose -f docker-compose.prod.yml ps

# View backend logs
docker compose -f docker-compose.prod.yml logs -f backend

# Test the API
curl https://api.yourdomain.com/health
```

## Local Development

### Backend

```bash
cd backend
npm install
cp .env.example .env  # fill in values
npm run dev
```

### Admin Panel

```bash
cd admin_panel
npm install
npm run dev
```

### Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

### Full Stack with Docker

```bash
docker compose up -d
```
