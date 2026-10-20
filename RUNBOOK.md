# Production Incident Runbook & Troubleshooting Guide

Buku panduan ini merinci langkah standar penanganan insiden operasional (*incident response*) untuk kluster **Hybrid Cloud Kubernetes**.

---

## 1. Insiden: Pod Berstatus `CrashLoopBackOff`

### Deskripsi Masalah
Kontainer di dalam Pod gagal menyala berulang kali setelah restart otomatis oleh kubelet.

### Langkah Diagnosa
1. Identifikasi Pod yang mengalami masalah:
   ```bash
   kubectl get pods -A | grep -E "CrashLoopBackOff|Error"
   ```
2. Periksa log kontainer terakhir sebelum mati:
   ```bash
   kubectl logs <nama-pod> --previous
   ```
3. Periksa riwayat event dan exit code:
   ```bash
   kubectl describe pod <nama-pod>
   ```

### Tindakan Penyelesaian
- **Exit Code 1**: Kesalahan pada aplikasi/konfigurasi runtime. Cek apakah ada environment variable yang salah atau file konfigurasi yang hilang.
- **Exit Code 137 / 143**: Kontainer dibunuh paksa oleh sistem operasi (sering berkaitan dengan kehabisan memori / OOMKilled).
- Perbaiki manifest konfigurasi di repositori Git, lalu biarkan ArgoCD melakukan *auto-sync*.

---

## 2. Insiden: Kontainer Terkena `OOMKilled` (Exit Code 137)

### Deskripsi Masalah
Penggunaan memori kontainer melampaui batas batas keras (`resources.limits.memory`) yang ditentukan pada manifest Kubernetes, sehingga kernel Linux membunuh proses tersebut.

### Langkah Diagnosa
1. Pastikan penyebabnya adalah `OOMKilled`:
   ```bash
   kubectl describe pod <nama-pod> | grep -i "OOMKilled"
   ```
2. Amati metrik konsumsi memori aktual di Grafana atau via terminal:
   ```bash
   kubectl top pod <nama-pod>
   ```

### Tindakan Penyelesaian
Sesuaikan alokasi batas memori pada manifest deployment (misal di `k8s/app-deployment.yaml`):
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi" # Naikkan batas memori agar tidak terbunuh
    cpu: "500m"
```
Commit dan push perubahan ke GitHub agar GitOps memperbarui pod secara mulus.

---

## 3. Insiden: Pemulihan Bencana Database (Database Outage & Restore)

### Deskripsi Masalah
Data pada kontainer database MySQL korup atau Pod database terhapus secara tidak sengaja.

### Prosedur Pemulihan (Disaster Recovery via MinIO)
1. Periksa daftar file backup terbaru yang tersimpan di MinIO:
   ```bash
   aws --endpoint-url=http://localhost:9000 s3 ls s3://database-backups/
   ```
2. Unduh arsip backup terbaru:
   ```bash
   aws --endpoint-url=http://localhost:9000 s3 cp s3://database-backups/<nama-file-backup>.tar.gz /tmp/
   ```
3. Ekstrak file SQL:
   ```bash
   tar -xzvf /tmp/<nama-file-backup>.tar.gz -C /tmp/
   ```
4. Injeksi kembali file SQL ke dalam Pod MySQL yang aktif di Kubernetes:
   ```bash
   MYSQL_POD=$(kubectl get pod -l app=mysql -o jsonpath="{.items[0].metadata.name}")
   cat /tmp/*.sql | kubectl exec -i "$MYSQL_POD" -- mysql -u root -p"password123" ecommerce
   ```
5. Verifikasi bahwa data tabel berhasil dipulihkan:
   ```bash
   kubectl exec -i "$MYSQL_POD" -- mysql -u root -p"password123" -e "SHOW TABLES IN ecommerce;"
   ```

---

## 4. Insiden: Terraform State Drift

### Deskripsi Masalah
Infrastruktur fisik mengalami perubahan manual di luar kendali Terraform, menyebabkan ketidakcocokan antara `terraform.tfstate` dengan kondisi aktual.

### Tindakan Penyelesaian
1. Masuk ke direktori terraform:
   ```bash
   cd terraform/
   ```
2. Segarkan status state file agar mencerminkan kondisi riil:
   ```bash
   terraform refresh
   ```
3. Bandingkan perbedaan sebelum menerapkan perubahan:
   ```bash
   terraform plan
   ```

---

## 5. Pembersihan Kapasitas Disk (Node DiskPressure)

### Deskripsi Masalah
Kapasitas disk pada VM/Node menipis akibat akumulasi image Docker yang tidak terpakai atau cache build.

### Tindakan Pembersihan Rutin
Jalankan pembersihan kontainer dan image usang yang tidak lagi aktif:
```bash
docker system prune -af --volumes
```
Verifikasi kembali ruang penyimpanan yang tersisa:
```bash
df -h /
```
