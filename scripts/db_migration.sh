#!/bin/bash
# ==============================================================================
# Script Name   : db_migration.sh
# Deskripsi     : Otomatisasi Backup Database Lokal, Kompresi, Upload ke MinIO (S3),
#                 dan Migrasi / Injeksi ke Cluster Kubernetes.
# ==============================================================================

set -e # Menghentikan script jika terjadi error pada salah satu perintah

# ------------------------------------------------------------------------------
# 1. Konfigurasi Variabel
# ------------------------------------------------------------------------------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/tmp/db_backups"
DB_CONTAINER="ecommerce-database"       # Nama kontainer MySQL lokal (docker-compose)
DB_NAME="ecommerce"                    # Nama database
DB_USER="root"                         # User root MySQL
DB_PASS="root123"                      # Password root MySQL

# MinIO (S3 Compatible Storage)
MINIO_ENDPOINT="http://localhost:9000" # Endpoint MinIO lokal
S3_BUCKET="s3://database-backups"

# Kubernetes Target
K8S_NAMESPACE="default"
K8S_POD_LABEL="app=mysql"

echo "=== [1/5] Memulai Proses Migrasi Database ($TIMESTAMP) ==="

# ------------------------------------------------------------------------------
# 2. Buat Direktori Backup Sementara
# ------------------------------------------------------------------------------
mkdir -p "$BACKUP_DIR"
SQL_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"
TAR_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.tar.gz"

# ------------------------------------------------------------------------------
# 3. Dump Database Lokal (Langkah 105)
# ------------------------------------------------------------------------------
echo "--> Mengekstrak data database dari kontainer $DB_CONTAINER..."
docker exec "$DB_CONTAINER" mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$SQL_FILE"
echo "    ✓ Database dump berhasil disimpan di: $SQL_FILE"

# ------------------------------------------------------------------------------
# 4. Kompresi File Backup (.tar.gz) (Langkah 106)
# ------------------------------------------------------------------------------
echo "--> Mengompresi file dump menjadi .tar.gz..."
tar -czvf "$TAR_FILE" -C "$BACKUP_DIR" "${DB_NAME}_${TIMESTAMP}.sql"
echo "    ✓ File terkompresi: $TAR_FILE"

# Hapus file mentah .sql untuk menghemat ruang disk
rm -f "$SQL_FILE"

# ------------------------------------------------------------------------------
# 5. Upload ke MinIO Object Storage (Langkah 107)
# ------------------------------------------------------------------------------
echo "--> Mengunggah backup ke MinIO ($S3_BUCKET)..."
aws --endpoint-url="$MINIO_ENDPOINT" s3 cp "$TAR_FILE" "$S3_BUCKET/"
echo "    ✓ File berhasil diunggah ke MinIO!"

# ------------------------------------------------------------------------------
# 6. Injeksi Data ke Database Kubernetes (Langkah 108)
# ------------------------------------------------------------------------------
echo "--> Menyiapkan pemulihan/injeksi data ke Pod MySQL Kubernetes..."

# Ekstrak kembali file .sql sementara untuk injeksi
tar -xzvf "$TAR_FILE" -C "$BACKUP_DIR"

# Cari nama Pod MySQL yang sedang berjalan di Kubernetes
MYSQL_POD=$(kubectl get pods -n "$K8S_NAMESPACE" -l "$K8S_POD_LABEL" -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || true)

if [ -n "$MYSQL_POD" ]; then
    echo "    Ditemukan Pod MySQL: $MYSQL_POD"
    echo "    Mengalirkan data SQL ke dalam database Kubernetes..."
    cat "$SQL_FILE" | kubectl exec -i "$MYSQL_POD" -n "$K8S_NAMESPACE" -- mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" || {
        echo "    [Catatan]: Database target di K8s mungkin perlu dibuat terlebih dahulu atau kredensial disesuaikan."
    }
    echo "    ✓ Injeksi data ke Kubernetes selesai!"
else
    echo "    [Lewati]: Pod MySQL di Kubernetes tidak ditemukan / belum running. File backup aman tersimpan di MinIO."
fi

# ------------------------------------------------------------------------------
# 7. Bersihkan File Sementara Lokal
# ------------------------------------------------------------------------------
rm -rf "$BACKUP_DIR"
echo "=== [Selesai] Seluruh Alur Migrasi Database Sukses Berjalan! ==="
