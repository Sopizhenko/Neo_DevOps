# Prometheus and Grafana Monitoring Module

# Helm release for Prometheus
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_chart_version
  namespace  = var.namespace

  create_namespace = true
  timeout          = 1200
  wait             = true

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "grafana.service.port"
    value = "80"
  }

  set {
    name  = "prometheus.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "prometheus.service.port"
    value = "9090"
  }

  depends_on = [var.cluster_name]
}

# ServiceMonitor for Django application (if needed)
resource "kubernetes_manifest" "django_service_monitor" {
  count = var.enable_django_monitoring ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "django-app-monitor"
      namespace = var.namespace
      labels = {
        app     = "django-app"
        release = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "django-app"
        }
      }
      endpoints = [
        {
          port     = "http"
          interval = "30s"
          path     = "/metrics"
        }
      ]
    }
  }

  depends_on = [helm_release.prometheus]
}
