# Bitwarden Lite Docker Compose

A streamlined Docker Compose configuration for self-hosting [Bitwarden Lite](https://bitwarden.com/help/install-and-deploy-lite/), optimized for personal use and home-labs.

## Overview

Bitwarden Lite is a single-container deployment of Bitwarden designed for:
- Personal use and home-lab environments
- Simplified configuration with reduced resource usage
- Support for multiple databases (SQLite, PostgreSQL, MySQL/MariaDB, MSSQL)
- ARM architecture compatibility (Raspberry Pi, NAS servers)

This Docker Compose configuration is designed to run on **Debian 12** with **nginx as a reverse proxy**.

## Features

- ✅ Single Docker Compose configuration
- ✅ Instance naming for collision avoidance (multi-instance support)
- ✅ Environment-based configuration (.env file)
- ✅ Support for multiple database backends
- ✅ Designed for nginx reverse proxy
- ✅ Security best practices
- ✅ Resource limits and health checks
- ✅ Easy backup and maintenance

## Prerequisites

### System Requirements
- **OS**: Debian 12 (or compatible Linux distribution)
- **RAM**: Minimum 200 MB for Bitwarden container
- **Storage**: Minimum 1 GB
- **Docker Engine**: Version 26+
- **nginx**: Installed and configured on the host

### Installation IDs
Before deployment, obtain your Bitwarden Installation ID and Key:
1. Visit https://bitwarden.com/host/
2. Enter your email address
3. Save the **Installation ID** and **Installation Key**

## Quick Start

### 1. Clone or Download

```bash
cd /opt
git clone <repository-url> bitwarden-lite
cd bitwarden-lite
```

### 2. Configure Environment Variables

Copy the example environment file and edit it:

```bash
cp .env.example .env
nano .env
```

**Required variables:**
- `INSTANCE_NAME`: Unique name for this instance (e.g., `bitwarden`)
- `BW_DOMAIN`: Your domain (e.g., `vault.example.com`)
- `BW_INSTALLATION_ID`: From https://bitwarden.com/host/
- `BW_INSTALLATION_KEY`: From https://bitwarden.com/host/
- Database credentials (see [ENVIRONMENT_VARIABLES.md](ENVIRONMENT_VARIABLES.md))

### 3. Choose Your Database

This configuration defaults to **SQLite** (simplest option). For other databases, see the database configuration section below.

### 4. Start the Stack

```bash
docker compose up -d
```

### 5. Configure nginx Reverse Proxy

Add this configuration to your nginx site:

```nginx
server {
    listen 80;
    server_name vault.example.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name vault.example.com;

    # SSL certificates (managed by certbot or manual)
    ssl_certificate /etc/letsencrypt/live/vault.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/vault.example.com/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # Proxy settings
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Client max body size (for attachments)
    client_max_body_size 100M;
}
```

Reload nginx:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 6. Access Your Vault

Navigate to `https://vault.example.com` and create your account.

## Database Configuration

### SQLite (Default)
Simple, file-based database. No additional configuration needed.

**Pros**: Easy setup, no separate database service
**Cons**: Not ideal for high-concurrency scenarios

### PostgreSQL (Recommended for Production)
```env
BW_DB_PROVIDER=postgresql
BW_DB_SERVER=postgres
BW_DB_DATABASE=bitwarden_vault
BW_DB_USERNAME=bitwarden
BW_DB_PASSWORD=your_strong_password_here
BW_DB_PORT=5432
```

Uncomment the PostgreSQL service in `docker-compose.yml`.

### MySQL/MariaDB
```env
BW_DB_PROVIDER=mysql
BW_DB_SERVER=mysql
BW_DB_DATABASE=bitwarden_vault
BW_DB_USERNAME=bitwarden
BW_DB_PASSWORD=your_strong_password_here
BW_DB_PORT=3306
```

Uncomment the MySQL service in `docker-compose.yml`.

## Maintenance

### View Logs
```bash
docker compose logs -f
```

### Restart Services
```bash
docker compose restart
```

### Stop Services
```bash
docker compose down
```

### Update Bitwarden
1. Backup your data (see Backup section)
2. Pull the latest image:
   ```bash
   docker compose pull
   ```
3. Recreate containers:
   ```bash
   docker compose up -d
   ```

### Backup

Refer to [docs/backups/README.md](docs/backups/README.md#L1-L85) for the consolidated backup and restore workflow (volumes, database dumps, scripts, verification, and security notes).

#### Automatic Backup Script
Create a backup script at `/opt/bitwarden-lite/backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/opt/bitwarden-backups"
DATE=$(date +%Y%m%d_%H%M%S)
INSTANCE_NAME="bitwarden"

mkdir -p "$BACKUP_DIR"

# Backup volumes
docker run --rm \
  -v ${INSTANCE_NAME}_bitwarden-data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/bitwarden_data_$DATE.tar.gz -C /data .

# Backup database (if using PostgreSQL)
# docker exec ${INSTANCE_NAME}-postgres pg_dump -U bitwarden bitwarden_vault > "$BACKUP_DIR/db_$DATE.sql"

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "bitwarden_data_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/bitwarden_data_$DATE.tar.gz"
```

Make it executable and add to cron:
```bash
chmod +x /opt/bitwarden-lite/backup.sh
# Add to cron: daily at 2 AM
echo "0 2 * * * /opt/bitwarden-lite/backup.sh" | crontab -
```

#### Manual Backup
```bash
# Stop the containers
docker compose down

# Backup the data volume
docker run --rm \
  -v bitwarden_bitwarden-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/bitwarden_backup_$(date +%Y%m%d).tar.gz -C /data .

# Restart
docker compose up -d
```

#### Restore from Backup
```bash
# Stop containers
docker compose down

# Restore data
docker run --rm \
  -v bitwarden_bitwarden-data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/bitwarden_backup_YYYYMMDD.tar.gz"

# Restart
docker compose up -d
```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker compose logs bitwarden

# Check if port is already in use
sudo netstat -tlnp | grep 8080

# Verify environment variables
docker compose config
```

### Can't access through nginx
1. Verify nginx configuration: `sudo nginx -t`
2. Check if Bitwarden is responding: `curl http://localhost:8080`
3. Review nginx error logs: `sudo tail -f /var/log/nginx/error.log`

### High memory usage
Adjust memory limits in `docker-compose.yml`:
```yaml
services:
  bitwarden:
    mem_limit: 512m  # Adjust as needed (minimum 200m)
```

### Database connection errors
1. Verify database credentials in `.env`
2. Check if database container is running: `docker compose ps`
3. Test database connectivity from Bitwarden container

## Security Considerations

1. **Always use HTTPS** - Configure SSL/TLS on nginx
2. **Strong passwords** - Use minimum 32 characters for database passwords
3. **Regular updates** - Keep Bitwarden and Docker updated
4. **Firewall rules** - Only expose nginx ports (80/443) to the internet
5. **Backup encryption** - Encrypt backups if stored off-site
6. **Two-factor authentication** - Enable 2FA for all accounts

## Advanced Configuration

For detailed information about all available environment variables, see [ENVIRONMENT_VARIABLES.md](ENVIRONMENT_VARIABLES.md).

### Optional Services

Enable/disable services in `.env`:
- `BW_ENABLE_ADMIN=true` - Admin panel (required)
- `BW_ENABLE_ICONS=true` - Website icons
- `BW_ENABLE_NOTIFICATIONS=true` - Push notifications
- `BW_ENABLE_SSO=false` - Enterprise SSO
- `BW_ENABLE_SCIM=false` - Enterprise SCIM

### SMTP Configuration

Configure email in `.env` for:
- Password reset emails
- Verification emails
- Organization invitations

### Multiple Instances

To run multiple instances, use different `INSTANCE_NAME` values:
```bash
# Instance 1
INSTANCE_NAME=bitwarden-prod
BW_PORT_HTTP=8080

# Instance 2
INSTANCE_NAME=bitwarden-test
BW_PORT_HTTP=8081
```

## Resources

- [Official Bitwarden Lite Documentation](https://bitwarden.com/help/install-and-deploy-lite/)
- [Bitwarden Community](https://community.bitwarden.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Bitwarden GitHub](https://github.com/bitwarden/self-host)
- [Bitwarden Lite Container Versions](https://github.com/bitwarden/self-host/pkgs/container/lite/versions?filters%5Bversion_type%5D=tagged&page=1)

## License

This Docker Compose configuration is provided as-is for self-hosting Bitwarden Lite. 
Bitwarden is licensed under the [Bitwarden License](https://github.com/bitwarden/server/blob/master/LICENSE.txt).

## Contributing

Contributions are welcome! Please:
1. Write all code, comments, and documentation in English
2. Follow the Docker Compose best practices outlined in [.github/copilot-instructions.md](.github/copilot-instructions.md)
3. Test your changes with different database configurations
4. Update documentation accordingly
