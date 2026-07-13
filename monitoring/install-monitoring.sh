#!/bin/bash
# ============================================================
#  ApexPOS - Monitoring Stack Installer
#  Installs kube-prometheus-stack (Prometheus + Grafana)
#  onto the K3s cluster via Helm.
#
#  Usage (run from devops-repo root):
#    bash monitoring/install-monitoring.sh
#
#  Access Grafana after install:
#    http://<EC2_PUBLIC_IP>:30300  (admin / ApexPOS@2026)
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MONITORING_VALUES="$REPO_ROOT/k8s/monitoring/kube-prometheus-values.yaml"
MONITORING_MANIFESTS="$REPO_ROOT/k8s/monitoring"
HELM_RELEASE="monitoring"
NAMESPACE="monitoring"

echo "========================================================"
echo "  ApexPOS Monitoring Stack Installer"
echo "  Prometheus + Grafana via kube-prometheus-stack"
echo "========================================================"
echo ""

# ── Step 1: Add Helm repository ──────────────────────────────
echo ">>> [1/5] Adding prometheus-community Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update
echo "    ✅ Helm repo ready."
echo ""

# ── Step 2: Create monitoring namespace ──────────────────────
echo ">>> [2/5] Applying monitoring namespace..."
kubectl apply -f "$MONITORING_MANIFESTS/namespace.yml"
echo "    ✅ Namespace 'monitoring' ensured."
echo ""

# ── Step 3: Install / Upgrade kube-prometheus-stack ──────────
echo ">>> [3/5] Installing kube-prometheus-stack (this may take 2-3 minutes)..."
helm upgrade --install "$HELM_RELEASE" prometheus-community/kube-prometheus-stack \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values "$MONITORING_VALUES" \
  --timeout 10m \
  --wait
echo "    ✅ kube-prometheus-stack deployed successfully."
echo ""

# ── Step 4: Apply custom ApexPOS dashboard & ServiceMonitor ──
echo ">>> [4/5] Applying ApexPOS custom Grafana dashboard and ServiceMonitor..."
kubectl apply -f "$MONITORING_MANIFESTS/apexpos-dashboard-configmap.yaml"
kubectl apply -f "$MONITORING_MANIFESTS/backend-servicemonitor.yaml"
echo "    ✅ Custom dashboard and ServiceMonitor applied."
echo ""

# ── Step 5: Verify all pods are running ──────────────────────
echo ">>> [5/5] Verifying monitoring pods..."
kubectl get pods -n "$NAMESPACE" -o wide
echo ""

# ── Print access details ──────────────────────────────────────
PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s ifconfig.me 2>/dev/null || echo "<EC2_IP>")

echo "========================================================"
echo "  ✅ Monitoring Stack Installation Complete!"
echo ""
echo "  🌐 Grafana URL : http://${PUBLIC_IP}:30300"
echo "  👤 Username    : admin"
echo "  🔑 Password    : ApexPOS@2026"
echo ""
echo "  📊 Custom Dashboards:"
echo "     → ApexPOS – Application Overview"
echo "     → Kubernetes / Compute Resources / Namespace (apexpos)"
echo "     → Node Exporter / Nodes"
echo ""
echo "  ⚠️  If port 30300 is blocked, run:"
echo "     kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
echo "========================================================"
