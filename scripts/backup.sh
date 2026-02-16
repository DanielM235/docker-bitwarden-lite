#!/usr/bin/env bash
# ============================================
# Bitwarden Lite - Backup Script
# ============================================
# Creates timestamped backups of the Bitwarden data volume and database.
# Run as a user with Docker permissions.
#
# Usage:
#   ./backup.sh                   # Uses default paths
#   ./backup.sh /custom/backup    # Override backup directory
#
# Schedule with cron (daily at 02:00):
#   0 2 * * * /opt/bitwarden-lite/scripts/backup.sh >> /var/log/bitwarden-backup.log 2>&1

set -euo pipefail

# ============================================
# Configuration
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_DIR}/.env"

# Load environment variables
if [[ -f "$ENV_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        # Parse key=value
        if [[ "$line" =~ ^[[:space:]]*([^=]+)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            export "$key"="$value"
        fi
    done < "$ENV_FILE"
else
    echo "ERROR: .env file not found at $ENV_FILE"
    exit 1
fi

# Backup destination (can be overridden via first argument)
BACKUP_DIR="${1:-/opt/bitwarden-backups}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-14}"
CONTAINER_NAME="${INSTANCE_NAME}-bitwarden-prod"
VOLUME_NAME="${INSTANCE_NAME}-bitwarden-data"
NETWORK_NAME="${INSTANCE_NAME}-bitwarden-network"
# Ensure backup directory exists with restrictive permissions
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

echo "============================================"
echo "Bitwarden Lite Backup - $TIMESTAMP"
echo "============================================"
echo "Instance:   ${INSTANCE_NAME}"
echo "Container:  ${CONTAINER_NAME}"
echo "DB Provider: ${BW_DB_PROVIDER}"
echo "Backup Dir: ${BACKUP_DIR}"
echo "Retention:  ${RETENTION_DAYS} days"
echo "============================================"

# ============================================
# Stop the Bitwarden service to quiesce writes
# ============================================
echo "[1/5] Stopping Bitwarden service..."
cd "$PROJECT_DIR"
docker compose stop bitwarden

# ============================================
# Backup data volume
# ============================================
DATA_ARCHIVE="${BACKUP_DIR}/bitwarden_data_${TIMESTAMP}.tar.gz"

echo "[2/5] Backing up data volume: $VOLUME_NAME"
docker run --rm \
    -v "${VOLUME_NAME}":/data:ro \
    -v "${BACKUP_DIR}":/backup \
    alpine sh -c "echo 'Contents of /data:' && ls -la /data && echo 'Creating archive...' && tar czf /backup/bitwarden_data_${TIMESTAMP}.tar.gz -C /data . && echo 'Archive created' && ls -la /backup/bitwarden_data_${TIMESTAMP}.tar.gz"
echo "       -> ${DATA_ARCHIVE}"

# ============================================
# Backup database
# ============================================
echo "[3/5] Backing up database (${BW_DB_PROVIDER})..."

case "${BW_DB_PROVIDER}" in
    postgresql)
        # PostgreSQL: dump using pg_dump inside a temporary container
        DB_DUMP="${BACKUP_DIR}/postgres_${TIMESTAMP}.sql.gz"
        docker run --rm \
            --network "${NETWORK_NAME}" \
            -e PGPASSWORD="${BW_DB_PASSWORD}" \
            -v "${BACKUP_DIR}":/backup \
            postgres:${POSTGRES_VERSION:-16-alpine} \
            pg_dump -h "${BW_DB_SERVER}" -U "${BW_DB_USERNAME}" "${BW_DB_DATABASE}" \
            | gzip > "${DB_DUMP}"
        echo "       -> ${DB_DUMP}"
        ;;
    mysql)
        # MySQL/MariaDB: dump using mysqldump
        DB_DUMP="${BACKUP_DIR}/mysql_${TIMESTAMP}.sql.gz"
        docker run --rm \
            --network "${NETWORK_NAME}" \
            -v "${BACKUP_DIR}":/backup \
            mysql:${MYSQL_VERSION:-8.0} \
            mysqldump -h "${BW_DB_SERVER}" -u "${BW_DB_USERNAME}" -p"${BW_DB_PASSWORD}" "${BW_DB_DATABASE}" \
            | gzip > "${DB_DUMP}"
        echo "       -> ${DB_DUMP}"
        ;;
    sqlite)
        # SQLite: copy the database file from the data volume
        DB_DUMP="${BACKUP_DIR}/vault_${TIMESTAMP}.db"
        docker run --rm \
            -v "${VOLUME_NAME}":/data:ro \
            -v "${BACKUP_DIR}":/backup \
            alpine cp /data/vault.db "/backup/vault_${TIMESTAMP}.db"
        echo "       -> ${DB_DUMP}"
        ;;
    *)
        echo "WARNING: Unknown database provider '${BW_DB_PROVIDER}', skipping database backup."
        ;;
esac

# ============================================
# Restart the Bitwarden service
# ============================================
echo "[4/5] Restarting Bitwarden service..."
docker compose start bitwarden

# ============================================
# Cleanup old backups
# ============================================
echo "[5/5] Cleaning up backups older than ${RETENTION_DAYS} days..."
find "$BACKUP_DIR" -name "bitwarden_data_*.tar.gz" -mtime +"${RETENTION_DAYS}" -delete
find "$BACKUP_DIR" -name "postgres_*.sql.gz" -mtime +"${RETENTION_DAYS}" -delete
find "$BACKUP_DIR" -name "mysql_*.sql.gz" -mtime +"${RETENTION_DAYS}" -delete
find "$BACKUP_DIR" -name "vault_*.db" -mtime +"${RETENTION_DAYS}" -delete

echo "============================================"
echo "Backup completed successfully!"
echo "Data:     ${DATA_ARCHIVE}"
[[ -n "${DB_DUMP:-}" ]] && echo "Database: ${DB_DUMP}"
echo "============================================"
