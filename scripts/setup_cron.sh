#!/bin/bash
# ==============================================================================
# Script Name   : setup_cron.sh
# Deskripsi     : Otomatisasi pendaftaran jadwal backup database ke Crontab Linux
# Jadwal        : Setiap hari jam 00:00 (Tengah Malam)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/db_migration.sh"
CRON_JOB="0 0 * * * $TARGET_SCRIPT >> /var/log/db_migration.log 2>&1"

echo "=== Mendaftarkan Jadwal Backup Otomatis ke Crontab ==="

# Pastikan script db_migration.sh memiliki izin eksekusi
chmod +x "$TARGET_SCRIPT"

# Cek apakah jadwal sudah pernah didaftarkan
if crontab -l 2>/dev/null | grep -F "$TARGET_SCRIPT" >/dev/null; then
    echo "✓ Jadwal backup sudah terdaftar sebelumnya di crontab."
else
    # Tambahkan jadwal tanpa menimpa entri crontab lain yang sudah ada
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✓ Sukses! Jadwal eksekusi otomatis berhasil ditambahkan: 0 0 * * *"
fi

echo "Jadwal Crontab saat ini:"
crontab -l
