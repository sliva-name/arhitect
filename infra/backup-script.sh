#!/bin/sh

# PostgreSQL Backup Script
# This script creates backups of PostgreSQL database and manages retention

set -e

BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/backup_${PGDATABASE}_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Create backup
echo "Creating backup: ${BACKUP_FILE}"
PGPASSWORD="${PGPASSWORD}" pg_dump -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" \
    --no-owner --no-acl | gzip > "${BACKUP_FILE}"

if [ $? -eq 0 ]; then
    echo "Backup created successfully: ${BACKUP_FILE}"
    
    # Get file size
    SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    echo "Backup size: ${SIZE}"
    
    # Remove old backups (older than RETENTION_DAYS)
    echo "Removing backups older than ${RETENTION_DAYS} days..."
    find "${BACKUP_DIR}" -name "backup_${PGDATABASE}_*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete
    
    echo "Backup completed successfully"
    exit 0
else
    echo "ERROR: Backup failed!"
    exit 1
fi

