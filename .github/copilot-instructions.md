# Copilot Instructions - Bitwarden Lite Docker Compose

## Project Overview

This project provides a Docker Compose configuration for self-hosting Bitwarden Lite, optimized for personal use and home-labs on Debian 12 with nginx as a reverse proxy.

## Core Principles

### Language Requirements
- **All code, scripts, comments, documentation, and commit messages MUST be in English**
- No exceptions - this ensures consistency and maintainability

### Docker Compose Best Practices

1. **Use Docker Compose Plugin Syntax**
   - Use `docker compose` (plugin) instead of `docker-compose` (standalone)
   - Commands: `docker compose up`, `docker compose down`, etc.

2. **Instance Naming for Collision Avoidance**
   - Always use `INSTANCE_NAME` environment variable to prefix container names
   - Format: `${INSTANCE_NAME}-bitwarden`, `${INSTANCE_NAME}-db`
   - This prevents container name collisions when running multiple instances

3. **Container Naming Convention**
   ```yaml
   services:
     bitwarden:
       container_name: ${INSTANCE_NAME}-bitwarden
   ```

4. **Project Name Configuration**
   - Set project name in docker-compose.yml or via environment variable
   - Use `name: ${INSTANCE_NAME}` at the top level of docker-compose.yml

### Environment Variables Strategy

1. **Maximize Use of .env File**
   - All configurable values MUST be environment variables
   - No hardcoded values in docker-compose.yml
   - Provide comprehensive .env.example with all options documented

2. **Variable Naming Convention**
   - Use uppercase with underscores: `INSTANCE_NAME`, `BW_DOMAIN`
   - Prefix Bitwarden-specific variables as per official docs: `BW_*`
   - Use descriptive names that explain purpose

3. **Required vs Optional Variables**
   - Clearly document which variables are required
   - Provide sensible defaults for optional variables
   - Use inline comments in .env.example to explain each variable

### Security Best Practices

1. **Secrets Management**
   - Never commit .env files
   - Use strong passwords (minimum 32 characters for databases)
   - Store sensitive data in environment variables, not in compose file

2. **Network Configuration**
   - Use custom bridge networks
   - Isolate database from external access
   - Only expose necessary ports

3. **File Permissions**
   - Set appropriate ownership for volumes
   - Use read-only mounts where possible
   - Document required permissions in README

### Host Integration (Debian 12 + nginx)

1. **Port Configuration**
   - Bitwarden should NOT expose port 80/443 directly to host
   - Use custom port (e.g., 8080) for nginx reverse proxy mapping
   - Configure via `BW_PORT_HTTP` environment variable

2. **Volume Mounts**
   - Use named volumes for persistence
   - Mount configuration directory: `/etc/bitwarden`
   - Keep data separate from configuration

3. **SSL/TLS Handling**
   - SSL termination handled by host nginx
   - Bitwarden runs in HTTP mode behind reverse proxy
   - Document nginx configuration requirements

### Database Considerations

1. **Supported Databases**
   - SQLite (default for simplicity)
   - PostgreSQL (recommended for production)
   - MySQL/MariaDB (alternative option)
   - MSSQL (enterprise option)

2. **Database Configuration**
   - Use dedicated database service in compose file
   - Configure via environment variables
   - Implement health checks
   - Use named volumes for data persistence

### Container Configuration

1. **Resource Limits**
   - Set memory limits (minimum 200MB for Bitwarden)
   - Configure CPU limits if needed
   - Document minimum requirements

2. **Restart Policies**
   - Use `restart: unless-stopped` for production
   - Document when to use `restart: always`

3. **Health Checks**
   - Implement health checks for all services
   - Use appropriate intervals and timeouts
   - Configure dependency ordering

### Documentation Standards

1. **README Requirements**
   - Clear installation instructions
   - Prerequisites section
   - Configuration guide
   - Troubleshooting section
   - Update/maintenance procedures

2. **Inline Documentation**
   - Comment complex configurations
   - Explain non-obvious choices
   - Document version requirements

3. **Environment Variables Documentation**
   - Maintain separate ENVIRONMENT_VARIABLES.md
   - Document all available options
   - Include examples and default values
   - Explain security implications

### Version Control

1. **Git Practices**
   - Meaningful commit messages in English
   - Semantic versioning for releases
   - Tag stable versions

2. **Files to Ignore**
   - .env files
   - Local overrides (docker-compose.override.yml)
   - Data directories
   - Logs and temporary files

### Maintenance

1. **Update Strategy**
   - Document update procedure
   - Use specific image tags, not `latest`
   - Test updates in non-production first
   - Maintain backup before updates

2. **Backup Recommendations**
   - Document backup procedures
   - Include database backup scripts
   - Specify what needs to be backed up

## Code Generation Guidelines

When generating or modifying code for this project:

1. Always check .env.example for variable names before creating new ones
2. Ensure docker-compose.yml references environment variables, never hardcoded values
3. Add comprehensive comments for non-obvious configurations
4. Follow Docker Compose file structure best practices
5. Test configurations with different database providers
6. Validate YAML syntax
7. Consider security implications of every configuration change
8. Document breaking changes in comments

## Bitwarden Lite Specifics

1. **Image Reference**
   - Use official image: `ghcr.io/bitwarden/lite`
   - Pin to specific version tag when possible
   - Document version compatibility

2. **Required Environment Variables**
   - BW_DOMAIN: Domain where Bitwarden will be accessed
   - BW_INSTALLATION_ID: From https://bitwarden.com/host/
   - BW_INSTALLATION_KEY: From https://bitwarden.com/host/
   - Database configuration variables (provider-specific)

3. **Volume Mounts**
   - Minimum: `/etc/bitwarden` for configuration and data
   - Optional: Separate volumes for backups

4. **Service Architecture**
   - Enable/disable services via environment variables
   - Consider resource usage when enabling optional services
   - Document implications of enabling/disabling services
