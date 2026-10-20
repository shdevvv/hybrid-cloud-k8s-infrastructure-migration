# Full-Stack Observability Guide (Prometheus & Grafana)

Modul ini mengimplementasikan pemantauan metrik kluster dan beban kerja kontainer secara *real-time* berbasis **kube-prometheus-stack**.

---

## 1. Komponen Utama
- **Prometheus Server**: Mengumpulkan (scraping) time-series metrics dari node Linux dan Pod Kubernetes.
- **Grafana**: Visualisasi interaktif metrik kluster melalui dashboard berbasis web.
- **Alertmanager**: Mesin pemicu notifikasi ketika terjadi anomali beban kerja (misalnya lonjakan CPU atau Pod crash).
- **Node Exporter & kube-state-metrics**: Agen pengekspor metrik perangkat keras dan status obyek Kubernetes.

---

## 2. Cara Deployment Cepat
Jalankan skrip instalasi otomatis:
```bash
chmod +x monitoring/deploy-monitoring.sh
./monitoring/deploy-monitoring.sh
```

---

## 3. Akses Dashboard Grafana
1. Jalankan port-forwarding dari terminal:
   ```bash
   kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
   ```
2. Buka browser di [http://localhost:3000](http://localhost:3000)
3. Kredensial default:
   - **Username**: `admin`
   - **Password**: `prom-operator`

---

## 4. Import Dashboard Unggulan
Di menu Grafana (`Dashboards -> New -> Import`), masukkan Dashboard ID standar industri berikut:
- **Dashboard ID 315**: *Kubernetes Cluster Monitoring (Metrics Server & Nodes)*
- **Dashboard ID 6417**: *Kubernetes Deployment / Pods Overview*
