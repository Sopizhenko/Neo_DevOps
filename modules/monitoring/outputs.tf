output "prometheus_url" {
  description = "Prometheus URL (requires port-forward)"
  value       = "http://localhost:9090"
}

output "grafana_url" {
  description = "Grafana URL (requires port-forward)"
  value       = "http://localhost:3000"
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = "admin"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "prometheus_namespace" {
  description = "Namespace where Prometheus is deployed"
  value       = var.namespace
}

output "port_forward_commands" {
  description = "Commands to access monitoring services"
  value = {
    grafana    = "kubectl port-forward svc/prometheus-grafana 3000:80 -n ${var.namespace}"
    prometheus = "kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n ${var.namespace}"
  }
}
