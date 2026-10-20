# Diagram Arsitektur Sistem Hybrid Cloud

Dokumen ini mendeskripsikan topologi dan alur lalu lintas data sistem *Hybrid Cloud Kubernetes Migration Pipeline*.

```mermaid
graph TD
    subgraph Client_Access ["🌐 Client & External Traffic"]
        User["End User / Browser"]
    end

    subgraph Edge_Networking ["🚪 Ingress & Load Balancing"]
        Ingress["Kubernetes Ingress / NodePort:30080"]
    end

    subgraph Kubernetes_Cluster ["☸️ Kubernetes Production Cluster (K3s / Local VM)"]
        subgraph App_Workloads ["Application Tier"]
            direction TB
            Frontend["Frontend Pods (Nginx / Replicas: 4)"]
            Backend["Backend Pods (Alpine API Service)"]
        end

        subgraph Data_Workloads ["Database Tier"]
            MySQL["MySQL 8.0 Pod (PV / PVC Storage 5Gi)"]
        end

        subgraph Monitoring_Stack ["Observability Tier"]
            Prometheus["Prometheus Server (Metrics Scraper)"]
            Grafana["Grafana Dashboard (:3000 / :30300)"]
            Alertmanager["Alertmanager Engine"]
        end
    end

    subgraph Storage_Tier ["☁️ Hybrid Cloud Object Storage (MinIO / S3)"]
        MinIO["MinIO S3 Compatible Storage (:9000)<br/>Bucket: s3://database-backups"]
    end

    subgraph Automation_Pipeline ["⚙️ DevOps & GitOps Automation"]
        GitHub["GitHub Repository (Source of Truth)"]
        GHActions["GitHub Actions (CI: Yamllint + Trivy Scan + Build & Push)"]
        GHCR["GitHub Container Registry (ghcr.io)"]
        ArgoCD["ArgoCD Controller (GitOps Continuous Sync & Self-Heal)"]
        Cronjob["Scheduled Backup Agent (Cron / Midnight 00:00)"]
    end

    User -->|HTTP Requests| Ingress
    Ingress -->|Forward Traffic| Frontend
    Frontend -->|API Calls| Backend
    Backend -->|Read / Write SQL| MySQL

    GitHub -->|Push Trigger| GHActions
    GHActions -->|Publish Secure Images| GHCR
    GHCR -.->|Pull Image| Frontend
    GitHub -->|Sync Manifests| ArgoCD
    ArgoCD -->|Reconcile & Deploy| Kubernetes_Cluster

    MySQL -.->|Daily mysqldump| Cronjob
    Cronjob -->|tar.gz Compressed Upload| MinIO
    MinIO -.->|Disaster Recovery Restore| MySQL

    Kubernetes_Cluster -.->|Expose Metrics| Prometheus
    Prometheus -->|Visualize Metrics| Grafana
    Prometheus -->|Fire Alerts (CPU / CrashLoop)| Alertmanager
```

---

### Alur Kerja Utama
1. **Jalur Akses Pengguna (Traffic Ingress)**:
   - Pengguna mengakses aplikasi melalui NodePort `30080` atau Ingress.
   - Trafik diteruskan ke Pod Frontend (Nginx dengan 4 replika untuk ketersediaan tinggi).
   - Frontend berkomunikasi dengan Pod Backend melalui Service Discovery internal K8s.
   - Backend membaca dan menulis transaksi ke Pod MySQL yang didukung oleh *Persistent Volume*.

2. **Jalur Otomatisasi (CI/CD & GitOps)**:
   - Pengembang melakukan `git push` ke branch `main`.
   - **GitHub Actions** menjalankan verifikasi kualitas (Yamllint) dan pemindaian celah keamanan (**Trivy**).
   - Image yang lolos scan dipublikasikan ke **GitHub Container Registry (GHCR)**.
   - **ArgoCD** mendeteksi perubahan deklaratif di Git dan melakukan rekonsiliasi otomatis (*auto-sync & self-heal*) ke kluster Kubernetes.

3. **Jalur Perlindungan Data (Disaster Recovery)**:
   - Agen backup otomatis menjalankan `mysqldump` setiap jam 00:00.
   - File dikompresi (`.tar.gz`) dan dikirim ke **MinIO (S3 Compatible Storage)**.
   - Apabila terjadi kerusakan kluster lokal, data dapat dipulihkan secara instan dari MinIO.
