variable "cluster_name" {
  description = "EKS cluster name"
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
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.7.5"
}

variable "github_repo_url" {
  description = "GitHub repository URL for GitOps"
  type        = string
  default     = "https://github.com/Sopizhenko/Neo_DevOps.git"
}

variable "github_target_revision" {
  description = "Git branch/tag to track"
  type        = string
  default     = "lesson-7"
}

variable "helm_chart_path" {
  description = "Path to Helm chart in repository"
  type        = string
  default     = "charts/django-app"
}
