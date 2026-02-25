# B-Act AI Labs - Deployment Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Deployment Options](#deployment-options)
3. [Prerequisites](#prerequisites)
4. [Local Development](#local-development)
5. [Production Deployment](#production-deployment)
6. [Configuration](#configuration)
7. [Monitoring & Logging](#monitoring--logging)
8. [Troubleshooting](#troubleshooting)

## Architecture Overview

B-Act AI Labs is a full-stack application with the following architecture:

```
┌─────────────────────────────────────────────────────┐
│                 End Users                            │
└──────────────────┬──────────────────────────────────┘
                   │ HTTPS
┌─────────────────┴────────────────────────────────────┐
│         Nginx Reverse Proxy (80, 443)                │
├─────────────────────────────────────────────────────┤
│ • Static Asset Serving (React Frontend)             │
│ • API Routing (/api/*, /auth/*)                     │
│ • SSL/TLS Termination                               │
│ • CORS Headers                                      │
└──────────────┬──────────────────────────────────────┘
               │ HTTP :3001
┌──────────────┴──────────────────────────────────────┐
│    Express.js Backend API Server                     │
├─────────────────────────────────────────────────────┤
│ • RESTful API Endpoints                             │
│ • Session Management                                │
│ • Business Logic                                    │
│ • Drizzle ORM                                       │
└──────────────┬──────────────────────────────────────┘
               │
┌──────────────┴──────────────────────────────────────┐
│    PostgreSQL Database (Neon)                        │
├─────────────────────────────────────────────────────┤
│ • User Data                                         │
│ • Progress Tracking                                 │
│ • Assessments                                       │
│ • Session Storage                                   │
└──────────────────────────────────────────────────────┘
```

## Deployment Options

### Option 1: Docker + VPS (Recommended for MVP)

**Hosting Providers:**
- DigitalOcean (Droplet)
- Linode
- AWS EC2
- Vultr
- Hetzner

**Pros:**
- Cost-effective ($5-20/month to start)
- Full control over environment
- Easy to scale vertically
- No vendor lock-in

**Cons:**
- Need to manage server maintenance
- Responsible for backups & updates
- Requires DevOps knowledge

---

### Option 2: Vercel + Render/Railway

**Frontend:** Vercel  
**Backend:** Render or Railway

**Pros:**
- Zero-config deployments
- Auto-scaling
- Built-in monitoring
- Easy to set up

**Cons:**
- Higher costs at scale
- Less control over infrastructure
- Vendor lock-in

---

### Option 3: AWS ECS/Fargate + RDS

**Pros:**
- Highly scalable
- Managed services
- Enterprise-grade security

**Cons:**
- Complex setup
- Expensive for small projects
- Steep learning curve

---

## Prerequisites

### System Requirements
- **Docker & Docker Compose** (v20.10+)
- **Node.js** 16+ (for local development)
- **PostgreSQL** 13+ (or Neon account)
- **Git**

### External Services
- **Neon Database**: PostgreSQL serverless hosting
- **Replit Auth**: OAuth2 provider
- **Stripe**: Payment processing (optional)
- **PostHog**: Analytics (optional)

---

## Local Development

### 1. Clone & Install

```bash
git clone https://github.com/bryanotieno23-dotcom/b-act-ai-labs.git
cd b-act-ai-labs

# Install frontend dependencies
cd frontend
npm install
cd ..

# Install backend dependencies
cd backend
npm install
cd ..
```

### 2. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit .env with local values
nano .env  # or your preferred editor
```

### 3. Local Database

```bash
# Using Docker Compose for PostgreSQL
docker-compose -f docker-compose.dev.yml up -d postgres

# Run migrations
cd backend
npm run migrate
cd ..
```

### 4. Development Servers

```bash
# Terminal 1: Frontend (Vite dev server)
cd frontend
npm run dev

# Terminal 2: Backend (Node dev server)
cd backend
npm run dev
```

Access at `http://localhost:5173` (frontend) and `http://localhost:3001` (backend)

---

## Production Deployment

### Step 1: Server Setup

#### For DigitalOcean Droplet:

```bash
# SSH into your server
ssh root@your_droplet_ip

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### Step 2: Clone Repository

```bash
# Create app directory
sudo mkdir -p /app/b-act-ai-labs
cd /app/b-act-ai-labs

# Clone repository
sudo git clone https://github.com/bryanotieno23-dotcom/b-act-ai-labs.git .

# Set permissions
sudo chown -R $USER:$USER /app/b-act-ai-labs
```

### Step 3: Configure Environment

```bash
# Copy environment file
cp .env.example .env

# Edit with production values
nano .env
```

**Critical production settings:**

```env
NODE_ENV=production
COOKIE_SECURE=true
REPLIT_AUTH_REDIRECT_URI=https://your-domain.com/auth/callback
NEXT_PUBLIC_API_URL=https://your-domain.com/api
```

### Step 4: SSL Certificates (Let's Encrypt)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Generate certificates
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com

# Update nginx.conf with certificate paths
# See "SSL Configuration" section below
```

### Step 5: Deploy with Docker Compose

```bash
# Build and start services
docker-compose up -d

# Check logs
docker-compose logs -f

# Verify health
curl http://localhost/health
```

### Step 6: Database Migrations

```bash
# Run initial migrations
docker-compose exec backend npm run migrate

# Check database connection
docker-compose exec postgres psql -U bactuser -d bact_labs -c "\dt"
```

### Step 7: Setup Monitoring

```bash
# View running containers
docker-compose ps

# Monitor logs
docker-compose logs -f backend

# Monitor resource usage
docker stats
```

---

## Configuration

### Environment Variables

See `.env.example` for all available options. Key production variables:

| Variable | Purpose | Example |
|----------|---------|---------|
| `DATABASE_URL` | PostgreSQL connection | `postgresql://user:pass@neon.tech/db` |
| `NODE_ENV` | Environment mode | `production` |
| `REPLIT_AUTH_CLIENT_ID` | OAuth client ID | From Replit dashboard |
| `REPLIT_AUTH_SECRET` | OAuth secret | From Replit dashboard |
| `STRIPE_SECRET_KEY` | Payment processing | `sk_live_...` |

### SSL Configuration

Update `nginx.conf` for HTTPS:

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Rest of nginx config...
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

### Database Backups

```bash
# Create daily backup script
cat > /app/b-act-ai-labs/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/app/backups"
mkdir -p $BACKUP_DIR
docker-compose exec postgres pg_dump -U bactuser bact_labs | gzip > $BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).sql.gz
EOF

chmod +x /app/b-act-ai-labs/backup.sh

# Add to crontab
crontab -e
# Add: 0 2 * * * /app/b-act-ai-labs/backup.sh
```

---

## Monitoring & Logging

### Docker Logs

```bash
# View logs
docker-compose logs [service]

# Follow logs in real-time
docker-compose logs -f backend

# View last 100 lines
docker-compose logs --tail=100 backend

# Filter by time
docker-compose logs --since 2024-01-01 backend
```

### Health Checks

```bash
# API health endpoint
curl https://your-domain.com/health

# Database connectivity
docker-compose exec backend npm run db:status

# Check running services
docker-compose ps
```

### Performance Monitoring

```bash
# CPU and memory usage
docker stats

# Disk space
df -h /app

# Network connections
netstat -tuln | grep 3001
```

---

## Troubleshooting

### Common Issues

#### 1. Port Already in Use

```bash
# Find what's using the port
sudo lsof -i :3001
# or
sudo netstat -tuln | grep 3001

# Kill the process
sudo kill -9 [PID]
```

#### 2. Database Connection Refused

```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Verify connection string
docker-compose exec backend echo $DATABASE_URL

# Check database logs
docker-compose logs postgres
```

#### 3. Docker Out of Disk Space

```bash
# Clean up dangling images
docker image prune -a

# Clean up volumes
docker volume prune

# Check disk usage
du -sh /var/lib/docker

# Clean all Docker data (warning: destructive)
docker system prune -a
```

#### 4. CORS Errors

Ensure backend CORS is configured:

```typescript
// backend/src/middleware/cors.ts
const cors = require('cors');

app.use(cors({
  origin: process.env.FRONTEND_URL,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

#### 5. SSL Certificate Issues

```bash
# Test certificate
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# Check certificate expiry
echo | openssl s_client -servername your-domain.com -connect your-domain.com:443 2>/dev/null | grep notAfter
```

### Debug Mode

Enable debug logging:

```bash
# Set debug environment variable
export DEBUG=* 
docker-compose restart backend

# View detailed logs
docker-compose logs -f backend
```

---

## Scaling

### Horizontal Scaling (Multiple Backend Instances)

```yaml
services:
  backend-1:
    build: .
    ports:
      - "3001:3001"
  
  backend-2:
    build: .
    ports:
      - "3002:3001"
  
  backend-3:
    build: .
    ports:
      - "3003:3001"
```

Nginx automatically load balances across instances.

### Vertical Scaling (Increase Server Size)

1. Backup database
2. Shut down services
3. Upgrade droplet
4. Restart services

---

## Security Best Practices

✅ Use environment variables for secrets  
✅ Enable SSL/TLS for all connections  
✅ Set up firewall rules  
✅ Regular database backups  
✅ Update dependencies regularly  
✅ Monitor logs for suspicious activity  
✅ Implement rate limiting  
✅ Use strong database passwords  
✅ Enable authentication on all endpoints  

---

## Support & Resources

- **Documentation**: See `/docs` directory
- **GitHub Issues**: Report bugs and request features
- **Docker Docs**: https://docs.docker.com
- **Nginx Docs**: https://nginx.org/en/docs/
- **PostgreSQL Docs**: https://www.postgresql.org/docs/

---

**Last Updated:** 2026-02-25 15:09:23  
**Version:** 1.0.0