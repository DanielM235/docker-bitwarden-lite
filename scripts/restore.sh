#!/usr/bin/env bash
# ============================================
# Bitwarden Lite - Restore Script
# ============================================
# Restores Bitwarden data volume and database from backup archives.
# Run as a user with Docker permissions.
#
# Usage:
#   ./restore.sh <data_archive> [db_dump]
#
# Examples:
#   ./restore.sh /opt/bitwarden-backups/bitwarden_data_20260201_020000.tar.gz
#   ./restore.sh /opt/bitwarden-backups/bitwarden_data_20260201_020000.tar.gz /opt/bitwarden-backups/postgres_20260201_020000.sql.gz

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

# ============================================
# Arguments
# ============================================
DATA_ARCHIVE="${1:-}"
DB_DUMP="${2:-}"

if [[ -z "$DATA_ARCHIVE" ]]; then
    echo "Usage: $0 <data_archive.tar.gz> [db_dump]"
    echo ""
    echo "Examples:"
    echo "  $0 /opt/bitwarden-backups/bitwarden_data_20260201_020000.tar.gz"
    echo "  $0 /opt/bitwarden-backups/bitwarden_data_20260201_020000.tar.gz /opt/bitwarden-backups/postgres_20260201_020000.sql.gz"
    exit 1
fi

if [[ ! -f "$DATA_ARCHIVE" ]]; then
    echo "ERROR: Data archive not found: $DATA_ARCHIVE"
    exit 1
fi

if [[ -n "$DB_DUMP" && ! -f "$DB_DUMP" ]]; then
    echo "ERROR: Database dump not found: $DB_DUMP"
    exit 1
fi

VOLUME_NAME="${INSTANCE_NAME}-bitwarden-data"
NETWORK_NAME="${INSTANCE_NAME}-bitwarden-network"

echo "============================================"
echo "Bitwarden Lite Restore"
echo "============================================"
echo "Instance:     ${INSTANCE_NAME}"
echo "DB Provider:  ${BW_DB_PROVIDER}"
echo "Data Archive: ${DATA_ARCHIVE}"
echo "DB Dump:      ${DB_DUMP:-<none>}"
echo "============================================"
echo ""
echo "WARNING: This will OVERWRITE the current Bitwarden data!"
read -rp "Are you sure you want to continue? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Restore cancelled."
    exit 0
fi

# ============================================
# Stop the stack
# ============================================
echo "[1/4] Stopping Bitwarden stack..."
cd "$PROJECT_DIR"
docker compose down

# ============================================
# Restore data volume
# ============================================
echo "[2/4] Restoring data volume: $VOLUME_NAME"

# Clear existing volume and restore
docker run --rm \
    -v "${VOLUME_NAME}":/data \
    -v "$(dirname "$DATA_ARCHIVE")":/backup:ro \
    alpine sh -c "rm -rf /data/* /data/..?* /data/.[!.]* 2>/dev/null || true; tar xzf /backup/$(basename "$DATA_ARCHIVE") -C /data"

echo "       -> Data volume restored."

# ============================================
# Restore database (if dump provided)
# ============================================
if [[ -n "$DB_DUMP" ]]; then
    echo "[3/4] Restoring database (${BW_DB_PROVIDER})..."

    # Start only the database container
    docker compose up -d "${BW_DB_SERVER}"
    echo "       Waiting for database to be ready..."
    sleep 10

    case "${BW_DB_PROVIDER}" in
        postgresql)
            if [[ "$DB_DUMP" == *.gz ]]; then
                gunzip -c "$DB_DUMP" | docker run --rm -i \
                    --network "${NETWORK_NAME}" \
                    -e PGPASSWORD="${BW_DB_PASSWORD}" \
                    postgres:${POSTGRES_VERSION:-16-alpine} \
                    psql -h "${BW_DB_SERVER}" -U "${BW_DB_USERNAME}" -d "${BW_DB_DATABASE}"
            else
                docker run --rm -i \
                    --network "${NETWORK_NAME}" \
                    -e PGPASSWORD="${BW_DB_PASSWORD}" \
                    -v "$(dirname "$DB_DUMP")":/backup:ro \
                    postgres:${POSTGRES_VERSION:-16-alpine} \
                    psql -h "${BW_DB_SERVER}" -U "${BW_DB_USERNAME}" -d "${BW_DB_DATABASE}" < "$DB_DUMP"
            fi
            ;;
        mysql)
            if [[ "$DB_DUMP" == *.gz ]]; then
                gunzip -c "$DB_DUMP" | docker run --rm -i \
                    --network "${NETWORK_NAME}" \
                    mysql:${MYSQL_VERSION:-8.0} \
                    mysql -h "${BW_DB_SERVER}" -u "${BW_DB_USERNAME}" -p"${BW_DB_PASSWORD}" "${BW_DB_DATABASE}"
            else
                docker run --rm -i \
                    --network "${NETWORK_NAME}" \
                    mysql:${MYSQL_VERSION:-8.0} \
                    mysql -h "${BW_DB_SERVER}" -u "${BW_DB_USERNAME}" -p"${BW_DB_PASSWORD}" "${BW_DB_DATABASE}" < "$DB_DUMP"
            fi
            ;;
        sqlite)
            # SQLite: copy the database file into the data volume
            docker run --rm \
                -v "${VOLUME_NAME}":/data \
                -v "$(dirname "$DB_DUMP")":/backup:ro \
                alpine cp "/backup/$(basename "$DB_DUMP")" /data/vault.db
            ;;
        *)
            echo "WARNING: Unknown database provider '${BW_DB_PROVIDER}', skipping database restore."
            ;;
    esac

    echo "       -> Database restored."
else
    echo "[3/4] Skipping database restore (no dump provided)."
fi

# ============================================
# Start the stack
# ============================================
echo "[4/4] Starting Bitwarden stack..."
docker compose up -d

# ============================================
# Verification
# ============================================
echo ""
echo "============================================"
echo "Restore completed!"
echo "============================================"
echo ""
echo "Verify the installation:"
echo "  curl http://localhost:${BW_PORT_HTTP:-8080}/alive"
echo "  docker compose logs --tail=50"
echo ""
