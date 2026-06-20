# 1. Target Namespaces
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
  }
}

# 2. Application Secrets (JWT, DB URL, etc.)
resource "kubernetes_secret" "backend_secrets" {
  metadata {
    name      = "backend-secrets"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    JWT_SECRET = "your-super-secret-jwt-key-change-this-in-production"
  }

  type = "Opaque"
}

# 3. ArgoCD Installation via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Enable local ingress for argocd.local
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.local"
  }

  # Force ArgoCD server to run insecurely (no SSL edge loop) for local ingress-nginx proxying
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }
}

# 4. Observability Stack (Prometheus + Grafana) via Helm
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.0.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # Easy admin credentials for development sandbox
  set {
    name  = "grafana.adminPassword"
    value = "admin"
  }

  # Enable Ingress for Grafana
  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  }

  set {
    name  = "grafana.ingress.ingressClassName"
    value = "nginx"
  }

  set {
    name  = "grafana.ingress.hosts[0]"
    value = "grafana.local"
  }

  # Enable prometheus node-exporter and scrape configs for local pod resource visualization
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
}
