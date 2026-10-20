#!/bin/bash
# ==============================================================================
# Script Name   : deploy-monitoring.sh
# Deskripsi     : Otomatisasi instalasi Prometheus & Grafana Stack via Helm
# ==============================================================================

set -e

NAMESPACE="monitoring"
RELEASE_NAME="monitoring"

echo "=== [1/4] Membuat Namespace Kubernetes: $NAMESPACE ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "=== [2/4] Mendaftarkan Helm Repository Prometheus ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "=== [3/4] Melakukan Deployment kube-prometheus-stack ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
helm upgrade --install "$RELEASE_NAME" prometheus-community/kube-prometheus-stack \
  --namespace "$NAMESPACE" \
  -f "$SCRIPT_DIR/prometheus-values.yaml"

echo "=== [4/4] Mengaplikasikan Aturan Alerting Kustom ==="
kubectl apply -f "$SCRIPT_DIR/alert-rules.yaml"

echo "✓ Seluruh komponen Observability berhasil terpasang!"
echo ""
echo "------------------------------------------------------------------"
echo "Cara Mengakses Dashboard Grafana:"
echo "1. Port Forwarding : kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80"
echo "2. URL Browser     : http://localhost:3000"
echo "3. Username        : admin"
echo "4. Password        : prom-operator"
echo "5. Rekomendasi Dashboard ID: 315 (Kubernetes Cluster) & 6417 (Pod Metrics)"
echo "------------------------------------------------------------------"
