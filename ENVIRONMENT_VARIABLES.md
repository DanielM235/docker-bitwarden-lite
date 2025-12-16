# Bitwarden Lite Environment Variables

Complete reference for all environment variables available in Bitwarden Lite deployment.

## Table of Contents

1. [Configuration Management](#configuration-management)
2. [Required Variables](#required-variables)
3. [Instance Configuration](#instance-configuration)
4. [Database Configuration](#database-configuration)
5. [Port Configuration](#port-configuration)
6. [SSL/TLS Configuration](#ssltls-configuration)
7. [Service Toggles](#service-toggles)
8. [SMTP Configuration](#smtp-configuration)
9. [Security & Authentication](#security--authentication)
10. [Advanced Configuration](#advanced-configuration)

---

## Configuration Management

Variables for tracking and managing configuration versions.

### CONFIG_VERSION
- **Description**: Configuration file version for tracking changes
- **Required**: No
- **Default**: `1.0.0`
- **Example**: `1.0.0`, `1.1.0`
- **Notes**: Helps identify which configuration template version is in use. Update this when making significant changes to your configuration.

### BW_VERSION
- **Description**: Bitwarden Lite Docker image version to use
- **Required**: No
- **Default**: `latest`
- **Example**: `latest`, `v2025.12.0`, `v2025.11.0`
- **Notes**: 
  - Use `latest` for automatic updates to the newest version
  - Pin to a specific version (e.g., `v2025.12.0`) for stability and controlled updates
  - Check available versions at: https://github.com/bitwarden/self-host/releases
  - Latest stable release: **v2025.12.0** (as of December 16, 2025)

---

## Required Variables

These variables **must** be set for Bitwarden Lite to function properly.

### BW_DOMAIN
- **Description**: The domain where Bitwarden will be accessed
- **Required**: Yes
- **Example**: `vault.example.com`
- **Notes**: Do not include `http://` or `https://` prefix

### BW_INSTALLATION_ID
- **Description**: Installation ID from Bitwarden
- **Required**: Yes
- **How to obtain**: Visit https://bitwarden.com/host/ and enter your email
- **Example**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **Notes**: Required for Bitwarden to function, even for self-hosted instances

### BW_INSTALLATION_KEY
- **Description**: Installation Key from Bitwarden
- **Required**: Yes
- **How to obtain**: Visit https://bitwarden.com/host/ and enter your email
- **Example**: `xxxxxxxxxxxxxxxxxxxx`
- **Notes**: Keep this secret - treat it like a password

---

## Instance Configuration

Variables for managing instance naming and avoiding container collisions.

### INSTANCE_NAME
- **Description**: Unique identifier for this Bitwarden instance
- **Required**: Yes (for this Docker Compose setup)
- **Default**: `bitwarden`
- **Example**: `bitwarden`, `bitwarden-prod`, `bitwarden-test`
- **Notes**: Used to prefix container names and networks. Allows running multiple instances on the same host without conflicts.

---

## Database Configuration

Bitwarden Lite supports multiple database providers: SQLite, PostgreSQL, MySQL/MariaDB, and MSSQL.

### BW_DB_PROVIDER
- **Description**: Database provider to use
- **Required**: Yes
- **Allowed values**: `sqlite`, `postgresql`, `mysql`, `mariadb`, `sqlserver`
- **Default**: `sqlite`
- **Example**: `postgresql`
- **Notes**: 
  - SQLite: Simplest, no additional database service needed
  - PostgreSQL: Recommended for production
  - MySQL/MariaDB: Alternative production option
  - MSSQL: Enterprise option

### BW_DB_SERVER
- **Description**: Database server hostname or IP
- **Required**: Yes (except for SQLite)
- **Example**: `postgres`, `mysql`, `192.168.1.100`
- **Notes**: Use service name from docker-compose.yml when using container database

### BW_DB_DATABASE
- **Description**: Name of the Bitwarden database
- **Required**: Yes (except for SQLite)
- **Default**: `bitwarden_vault`
- **Example**: `bitwarden_vault`, `bitwarden`
- **Notes**: Database must exist before starting Bitwarden

### BW_DB_USERNAME
- **Description**: Database username
- **Required**: Yes (except for SQLite)
- **Example**: `bitwarden`
- **Security**: Create a dedicated user with only necessary permissions

### BW_DB_PASSWORD
- **Description**: Database password
- **Required**: Yes (except for SQLite)
- **Example**: `your_super_secure_password_min_32_chars`
- **Security**: 
  - Use minimum 32 characters
  - Mix uppercase, lowercase, numbers, and symbols
  - Never commit to version control
  - Rotate regularly

### BW_DB_PORT
- **Description**: Custom database port
- **Required**: No
- **Default**: Depends on provider (PostgreSQL: 5432, MySQL: 3306, MSSQL: 1433)
- **Example**: `5432`
- **Notes**: Only needed if using non-standard port

### BW_DB_FILE
- **Description**: Path to SQLite database file
- **Required**: No (only for SQLite)
- **Default**: `/etc/bitwarden/vault.db`
- **Example**: `/etc/bitwarden/custom_vault.db`
- **Notes**: Path must be within mounted volume

---

## Port Configuration

Configure which ports Bitwarden uses for HTTP/HTTPS traffic.

### BW_PORT_HTTP
- **Description**: Port for HTTP traffic inside the container
- **Required**: No
- **Default**: `8080`
- **Example**: `8080`, `8081`, `8082`
- **Notes**: 
  - Map this port to host for nginx reverse proxy
  - Different instances should use different ports
  - Do not use port 80 when behind reverse proxy

### BW_PORT_HTTPS
- **Description**: Port for HTTPS traffic inside the container
- **Required**: No
- **Default**: `8443`
- **Example**: `8443`, `8444`
- **Notes**: 
  - Only needed if SSL is handled by Bitwarden container
  - Typically not used when behind nginx reverse proxy

---

## SSL/TLS Configuration

SSL/TLS settings for Bitwarden container. When using nginx reverse proxy, these are typically not needed.

### BW_ENABLE_SSL
- **Description**: Enable SSL/TLS in Bitwarden container
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `false`
- **Notes**: 
  - Set to `false` when using nginx reverse proxy (recommended)
  - Set to `true` only if handling SSL within container

### BW_SSL_CERT
- **Description**: Name of SSL certificate file
- **Required**: No (only if BW_ENABLE_SSL=true)
- **Default**: `ssl.crt`
- **Example**: `bitwarden.crt`
- **Notes**: File must be in `/etc/bitwarden` directory

### BW_SSL_KEY
- **Description**: Name of SSL private key file
- **Required**: No (only if BW_ENABLE_SSL=true)
- **Default**: `ssl.key`
- **Example**: `bitwarden.key`
- **Notes**: File must be in `/etc/bitwarden` directory

### BW_ENABLE_SSL_CA
- **Description**: Use SSL with Certificate Authority
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `false`

### BW_SSL_CA_CERT
- **Description**: Name of SSL CA certificate file
- **Required**: No (only if BW_ENABLE_SSL_CA=true)
- **Default**: `ca.crt`
- **Notes**: File must be in `/etc/bitwarden` directory

### BW_ENABLE_SSL_DH
- **Description**: Use SSL with Diffie-Hellman key exchange
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `false`

### BW_SSL_DH_CERT
- **Description**: Name of Diffie-Hellman parameters file
- **Required**: No (only if BW_ENABLE_SSL_DH=true)
- **Default**: `dh.pem`
- **Notes**: File must be in `/etc/bitwarden` directory

### BW_SSL_PROTOCOLS
- **Description**: SSL/TLS protocols to enable
- **Required**: No
- **Default**: System default (recommended)
- **Example**: `TLSv1.2 TLSv1.3`
- **Notes**: Leave empty for recommended defaults

### BW_SSL_CIPHERS
- **Description**: SSL cipher suites to enable
- **Required**: No
- **Default**: System default (recommended)
- **Notes**: Leave empty for recommended defaults. Advanced users only.

---

## Service Toggles

Enable or disable optional Bitwarden services to optimize resource usage.

### BW_ENABLE_ADMIN
- **Description**: Enable admin panel
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `true`
- **Notes**: **Do not disable** - Required for administration tasks
- **Access**: `https://yourdomain.com/admin`

### BW_ENABLE_API
- **Description**: Enable API service
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `true`
- **Notes**: **Do not disable** - Required for client applications

### BW_ENABLE_IDENTITY
- **Description**: Enable identity service
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `true`
- **Notes**: **Do not disable** - Required for authentication

### BW_ENABLE_ICONS
- **Description**: Enable website icon service
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `true`
- **Notes**: 
  - Shows website favicons for login items
  - Disabling saves memory but removes icons
  - See `BW_ICONS_PROXY_TO_CLOUD` for alternative

### BW_ICONS_PROXY_TO_CLOUD
- **Description**: Proxy icon requests to Bitwarden cloud services
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `false`
- **Notes**: 
  - Reduces memory usage by offloading to cloud
  - Set `BW_ENABLE_ICONS=false` when using this option
  - Requires outbound internet access

### BW_ENABLE_NOTIFICATIONS
- **Description**: Enable push notification service
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `true`
- **Notes**: 
  - Required for mobile push notifications
  - Required for "Login with Device" feature
  - Required for automatic vault sync on mobile

### BW_ENABLE_EVENTS
- **Description**: Enable event logging
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `false`
- **Notes**: 
  - For Teams and Enterprise event monitoring
  - Creates audit logs of user actions
  - Increases database size

### BW_ENABLE_SSO
- **Description**: Enable SSO (Single Sign-On) service
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `false`
- **Notes**: 
  - Enterprise feature only
  - Requires valid Enterprise license

### BW_ENABLE_SCIM
- **Description**: Enable SCIM (System for Cross-domain Identity Management)
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `false`
- **Notes**: 
  - Enterprise feature only
  - For automated user provisioning
  - Requires valid Enterprise license

---

## SMTP Configuration

Email configuration for password resets, account verification, and organization invitations.

### globalSettings__mail__replyToEmail
- **Description**: Reply-to email address for Bitwarden emails
- **Required**: Recommended
- **Example**: `no-reply@example.com`
- **Notes**: Users will see this as the sender

### globalSettings__mail__smtp__host
- **Description**: SMTP server hostname
- **Required**: For email functionality
- **Example**: `smtp.gmail.com`, `mail.example.com`

### globalSettings__mail__smtp__port
- **Description**: SMTP server port
- **Required**: For email functionality
- **Common values**: 
  - `587` - TLS (STARTTLS)
  - `465` - SSL
  - `25` - Unencrypted (not recommended)
- **Example**: `587`

### globalSettings__mail__smtp__ssl
- **Description**: Use SSL for SMTP connection
- **Required**: For email functionality
- **Allowed values**: `true`, `false`
- **Default**: `false`
- **Notes**: 
  - Set to `true` for port 465 (SSL)
  - Set to `false` for port 587 (STARTTLS/TLS)

### globalSettings__mail__smtp__username
- **Description**: SMTP authentication username
- **Required**: For email functionality (if SMTP requires auth)
- **Example**: `smtp-user@example.com`

### globalSettings__mail__smtp__password
- **Description**: SMTP authentication password
- **Required**: For email functionality (if SMTP requires auth)
- **Security**: Store securely, never commit to version control

---

## Security & Authentication

Security and authentication configuration options.

### globalSettings__disableUserRegistration
- **Description**: Disable new user registration
- **Required**: No
- **Allowed values**: `true`, `false`
- **Default**: `false`
- **Notes**: 
  - Set to `true` after creating your account to prevent unauthorized signups
  - You can still invite users via admin panel

### adminSettings__admins
- **Description**: Email addresses of admin users
- **Required**: Recommended
- **Example**: `admin@example.com,admin2@example.com`
- **Format**: Comma-separated list of email addresses
- **Notes**: These users have access to the `/admin` panel

### globalSettings__hibpApiKey
- **Description**: Have I Been Pwned API key
- **Required**: No
- **How to obtain**: Register at https://haveibeenpwned.com/API/Key
- **Example**: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
- **Notes**: 
  - Enables password breach checking
  - Free tier has rate limits
  - Paid tier for production use

### globalSettings__yubico__clientId
- **Description**: Yubico API client ID for YubiKey 2FA
- **Required**: No (only for YubiKey 2FA)
- **How to obtain**: https://upgrade.yubico.com/getapikey/
- **Example**: `12345`

### globalSettings__yubico__key
- **Description**: Yubico API secret key
- **Required**: No (only for YubiKey 2FA)
- **How to obtain**: https://upgrade.yubico.com/getapikey/
- **Security**: Keep secret

---

## Advanced Configuration

Advanced settings for specific use cases.

### BW_REAL_IPS
- **Description**: Define real client IPs from proxy servers
- **Required**: No
- **Example**: `192.168.1.1,10.0.0.1`
- **Format**: Comma-separated list of IP addresses or CIDR ranges
- **Notes**: 
  - Useful when behind reverse proxy
  - Helps with accurate IP logging and rate limiting
  - Add your nginx server IP here

### BW_CSP
- **Description**: Content Security Policy header
- **Required**: No
- **Default**: Bitwarden's default CSP
- **Notes**: 
  - **Warning**: Modifying may break features
  - Only change if you understand CSP implications
  - You become responsible for maintaining this value

### Docker Compose Specific Variables

These variables are specific to this Docker Compose configuration and not part of Bitwarden Lite itself.

#### POSTGRES_VERSION
- **Description**: PostgreSQL Docker image version
- **Default**: `16-alpine`
- **Example**: `16-alpine`, `15-alpine`

#### POSTGRES_PASSWORD
- **Description**: PostgreSQL superuser password
- **Security**: Must match `BW_DB_PASSWORD` if using PostgreSQL
- **Notes**: Only used when deploying PostgreSQL service

#### MYSQL_VERSION
- **Description**: MySQL Docker image version
- **Default**: `8.0`
- **Example**: `8.0`, `8.4`

#### MYSQL_ROOT_PASSWORD
- **Description**: MySQL root password
- **Security**: Use strong password, different from BW_DB_PASSWORD
- **Notes**: Only used when deploying MySQL service

---

## Environment Variable Priority

Variables can be set in multiple ways. Priority order (highest to lowest):

1. Command line `docker compose` arguments (`--env` flag)
2. `.env` file in the same directory as `docker-compose.yml`
3. Environment variables exported in shell
4. Default values in Bitwarden Lite

## Security Best Practices

1. **Never commit `.env` file** - Use `.env.example` as template
2. **Use strong passwords** - Minimum 32 characters for database passwords
3. **Rotate secrets regularly** - Especially database passwords and SMTP credentials
4. **Limit service exposure** - Only enable services you need
5. **Disable registration** - Set `globalSettings__disableUserRegistration=true` after setup
6. **Use HTTPS** - Always terminate SSL at nginx, never use plain HTTP
7. **Backup secrets** - Store `.env` file securely as part of backup strategy
8. **Monitor access** - Enable event logging for audit trails

## Example Configurations

### Minimal SQLite Setup
```env
INSTANCE_NAME=bitwarden
BW_DOMAIN=vault.example.com
BW_INSTALLATION_ID=your-installation-id
BW_INSTALLATION_KEY=your-installation-key
BW_DB_PROVIDER=sqlite
BW_PORT_HTTP=8080
```

### Production PostgreSQL Setup
```env
INSTANCE_NAME=bitwarden-prod
BW_DOMAIN=vault.example.com
BW_INSTALLATION_ID=your-installation-id
BW_INSTALLATION_KEY=your-installation-key
BW_DB_PROVIDER=postgresql
BW_DB_SERVER=postgres
BW_DB_DATABASE=bitwarden_vault
BW_DB_USERNAME=bitwarden
BW_DB_PASSWORD=super_secure_password_min_32_chars_here
BW_PORT_HTTP=8080
BW_ENABLE_EVENTS=true
globalSettings__disableUserRegistration=true
adminSettings__admins=admin@example.com
```

### High-Performance Setup with Cloud Icons
```env
INSTANCE_NAME=bitwarden
BW_DOMAIN=vault.example.com
BW_INSTALLATION_ID=your-installation-id
BW_INSTALLATION_KEY=your-installation-key
BW_DB_PROVIDER=postgresql
BW_DB_SERVER=postgres
BW_DB_DATABASE=bitwarden_vault
BW_DB_USERNAME=bitwarden
BW_DB_PASSWORD=super_secure_password_min_32_chars_here
BW_PORT_HTTP=8080
BW_ENABLE_ICONS=false
BW_ICONS_PROXY_TO_CLOUD=true
```

## Resources

- [Official Bitwarden Lite Documentation](https://bitwarden.com/help/install-and-deploy-lite/)
- [Bitwarden Self-Host GitHub](https://github.com/bitwarden/self-host)
- [Bitwarden Community Forum](https://community.bitwarden.com/)
