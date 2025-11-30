variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for monitoring tools"
  type        = string
  default     = "monitoring"
}

variable "prometheus_chart_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "55.5.0"
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Prometheus storage size"
  type        = string
  default     = "50Gi"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "enable_django_monitoring" {
  description = "Enable Django application monitoring"
  type        = bool
  default     = false
}
