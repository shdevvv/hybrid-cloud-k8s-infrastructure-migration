# 📋 Peta Eksekusi Mega-Project (BAB 1 - 11) - Status & Dokumentasi Lengkap

> **Catatan Portofolio Magang**: Dokumen ini merangkum seluruh langkah implementasi, perintah terminal, dan verifikasi dari BAB 1 hingga BAB 11.

---

## BAB 1: SETUP LINGKUNGAN KERJA LOKAL & SIMULASI CLOUD (Selesai)
- [x] **1. VS Code:** Instalasi Visual Studio Code di laptop.
- [x] **2. Ekstensi:** Install ekstensi HashiCorp Terraform, Docker, YAML, Remote - SSH.
- [x] **3-5. Git Config:** Instalasi Git, `git config --global user.name` dan `user.email`.
- [x] **6-8. CLI Setup:** Instalasi AWS CLI dan Terraform CLI, verifikasi dengan `aws --version` dan `terraform --version`.
- [x] **9-10. VM Ubuntu:** Provisi VM Ubuntu (`Cloud-K8s-Server`) dengan VirtualBox / Multipass.
- [x] **11-12. AWS Dummy Configure:** Konfigurasi `aws configure` (Access Key: test, Secret: test, Region: us-east-1).
- [x] **13-14. Simulasi Object Storage (Localstack / MinIO):** Menjalankan kontainer simulasi API AWS S3 lokal.

---

## BAB 2: INFRASTRUCTURE AS CODE (TERRAFORM) (Selesai)
- [x] **15-19. Proyek & Provider:** Membuat folder `terraform/`, file `provider.tf` dengan provider `local` / `multipass`.
- [x] **20-23. Jaringan Terisolasi:** File `vpc.tf` mendefinisikan alokasi subnet CIDR `10.0.0.0/16` dan pemisahan tier.
- [x] **24-27. Virtual Server & Outputs:** File `main.tf` dan `outputs.tf` menampilkan IP server lokal target (`192.168.1.103`).
- [x] **28-33. Eksekusi Terraform:** Menjalankan `terraform init`, `terraform plan`, dan `terraform apply -auto-approve`. Koneksi SSH ke VM berhasil.

---

## BAB 3: AUTOMATED CONFIGURATION MANAGEMENT (ANSIBLE) (Selesai)
- [x] **34-38. Inventory & Ansible Config:** Folder `ansible/`, file `inventory.ini` mendaftarkan host IP `192.168.1.103`, `ansible.cfg` mengatur `host_key_checking = False`.
- [x] **39-41. Playbook Security Hardening:** File `security_hardening.yml` mematikan root SSH (`PermitRootLogin no`) dan mengaktifkan UFW firewall port 22.
- [x] **42-44. Playbook Docker Engine:** File `install_docker.yml` menginstal `docker.io`, mengaktifkan service Docker, dan menambahkan user `ubuntu` ke grup `docker`.
- [x] **45-47. Eksekusi Playbook:** Menjalankan `ansible-playbook -i inventory.ini security_hardening.yml` dan `install_docker.yml`. Verifikasi via `docker --version`.

---

## BAB 4: CONTAINERIZATION (DOCKER & DOCKER COMPOSE) (Selesai)
- [x] **48-51. Dockerfiles:** Folder `app/frontend/Dockerfile` (Nginx Alpine) dan `app/backend/Dockerfile` (Alpine API Service).
- [x] **52-54. Multi-Container Compose:** File `app/docker-compose.yml` mengintegrasikan service frontend, backend, dan MySQL database beserta environment variables.
- [x] **55-57. Pengujian Lokal:** Menjalankan `docker-compose up -d`, pengujian akses HTTP di port 3000, lalu `docker-compose down`.
- [x] **58-63. Container Registry (GHCR):** Pembuatan Personal Access Token (PAT) GitHub, `docker login ghcr.io`, build tag versi `v1.0.0`, dan push image frontend & backend ke GitHub Packages.

---

## BAB 5: KUBERNETES ORCHESTRATION (K3s) (Selesai)
- [x] **64-67. K3s Cluster & kubectl:** Instalasi K3s lightweight Kubernetes di VM Linux (`curl -sfL https://get.k3s.io | sh -`), verifikasi kluster dengan `kubectl get nodes`.
- [x] **68-73. Kubernetes Manifests:**
  - `k8s/mysql-pv.yaml`: PersistentVolume (PV) dan PersistentVolumeClaim (PVC) penyimpanan 5Gi.
  - `k8s/mysql-deployment.yaml`: MySQL 8.0 deployment dan ClusterIP service.
  - `k8s/app-deployment.yaml`: Deployment aplikasi web.
  - `k8s/app-service.yaml`: Service NodePort (port `30080`).
- [x] **74-78. Deployment ke Cluster:** `kubectl apply -f k8s/`, verifikasi seluruh Pod berstatus `Running`, dan pengujian akses via NodePort `http://192.168.1.103:30080`.

---

## BAB 6: AUTOMATED CI/CD PIPELINE (GITHUB ACTIONS) (Selesai)
- [x] **79-82. Repository & Secrets:** Repositori GitHub terhubung, konfigurasi secrets `GHCR_USERNAME` dan `GHCR_TOKEN`.
- [x] **83-88. CI/CD Workflow (`.github/workflows/ci-cd.yml`):**
  - Trigger otomatis saat `push` ke branch `main`.
  - Tahap 1: Linting kode YAML (`yamllint`) dan validasi struktur docker-compose.
  - Tahap 2: Vulnerability scanning image kontainer menggunakan **Trivy Scanner** (Aquasecurity).
  - Tahap 3: Otomatisasi Docker Build & Push ke GHCR dengan SHA commit & tag `v1.0.0`.
- [x] **89-91. Pengujian Pipeline:** Commit dan push ke branch main, seluruh job di tab GitHub Actions berhasil centang hijau (🟢).

---

## BAB 7: GITOPS AUTOMATION DENGAN ARGOCD (Selesai)
- [x] **92-95. Instalasi ArgoCD:** Membuat namespace `argocd`, menerapkan manifest stable ArgoCD, mengekstrak password admin bawaan, dan port-forwarding dashboard.
- [x] **96-99. GitOps Synchronization:** Menghubungkan repositori GitHub ke ArgoCD, mengatur sinkronisasi otomatis (*Automated Sync, Prune, Self-Heal*).
- [x] **100-102. Zero-Downtime Scaling Test:** Mengubah replika pod pada `k8s/app-deployment.yaml` dari 2 menjadi 4, push commit `scale app replicas to 4`, ArgoCD otomatis mendeteksi dan melipatgandakan Pod tanpa downtime.

---

## BAB 8: HYBRID-CLOUD DATA MIGRATION & MINIO STORAGE (Selesai)
- [x] **103-108. Script Migrasi (`scripts/db_migration.sh`):**
  - Melakukan `mysqldump` dari kontainer database lokal.
  - Mengompresi file dump menjadi `.tar.gz`.
  - Mengunggah file backup ke MinIO Object Storage (`s3://database-backups`) via AWS CLI.
  - Menyiapkan logika pemulihan/injeksi data ke dalam Pod MySQL Kubernetes.
- [x] **109-110. Izin Eksekusi:** File script disetel berizin `chmod +x` (mode `100755` di Git).
- [x] **111-112. Otomatisasi Jadwal (Cron):**
  - Script `scripts/setup_cron.sh` untuk mendaftarkan jadwal backup otomatis setiap tengah malam (`0 0 * * *`).
  - Manifest `k8s/db-backup-cronjob.yaml` untuk penjadwalan native di dalam kluster Kubernetes.

---

## BAB 9: FULL-STACK OBSERVABILITY (PROMETHEUS & GRAFANA) (Selesai)
- [x] **113-116. Helm & Stack Monitoring:**
  - Script otomatisasi `monitoring/deploy-monitoring.sh` untuk pendaftaran repository Helm Prometheus Community.
  - Konfigurasi custom Helm values di `monitoring/prometheus-values.yaml` (Grafana NodePort 30300, resource requests/limits).
- [x] **117-120. Grafana Dashboard:**
  - Panduan akses di `monitoring/README.md` (port-forward `3000:80`, user: `admin`, password: `prom-operator`).
  - Rekomendasi Dashboard ID industri: **ID 315** (Cluster Overview) & **ID 6417** (Pod Metrics).
- [x] **121. Alertmanager Rules (`monitoring/alert-rules.yaml`):**
  - Aturan deteksi lonjakan CPU tinggi (> 80% selama 5 menit).
  - Aturan deteksi Pod mengalami `CrashLoopBackOff`.

---

## BAB 10: DOKUMENTASI LENGKAP & STANDAR PORTOFOLIO (Selesai)
- [x] **122-124. Visualisasi Arsitektur:**
  - Diagram alur lalu lintas data di `docs/architecture.mmd` dan `docs/architecture.md` (User -> Ingress -> Frontend -> Backend -> MySQL -> MinIO).
- [x] **125. Production Runbook (`RUNBOOK.md`):**
  - Panduan troubleshooting insiden operasional: `CrashLoopBackOff`, `OOMKilled`, Pemulihan database darurat, Terraform state drift, dan pembersihan disk node.
- [x] **126-128. Master README (`README.md`):**
  - Dokumentasi berstandar portofolio internasional lengkap dengan badge status CI/CD, deskripsi arsitektur, tabel teknologi, struktur direktori, dan panduan quick start.

---

## BAB 11: MENGUASAI TROUBLESHOOTING & DRILL INTERVIEW (Siap)
- [x] **129-132. Pemahaman Troubleshooting Lapangan:**
  - Mendiagnosa Pod gagal booting: `kubectl logs <pod> --previous` & `kubectl describe pod <pod>`.
  - Mencegah kontainer mati akibat `OOMKilled` (Exit Code 137) dengan menyesuaikan `resources.limits.memory`.
  - Penanganan sinkronisasi status infrastruktur dengan `terraform refresh`.
  - Pembersihan resource lokal yang menumpuk dengan `docker system prune -af`.
- [x] **133-134. Kesiapan Wawancara (Interview Drill):**
  - Penguasaan cerita arsitektur proyek dalam kurun waktu 3 menit menggunakan metode **STAR (Situation, Task, Action, Result)**.
  - Penguasaan konsep kunci: **Hybrid-Cloud Disaster Recovery**, **Infrastructure as Code**, dan **GitOps Continuous Reconciliation**.
