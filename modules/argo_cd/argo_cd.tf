resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      namespace = var.namespace
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Deploy Argo CD Application using local Helm chart
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "repository.url"
    value = var.github_repo_url
  }

  set {
    name  = "application.targetRevision"
    value = var.github_target_revision
  }

  set {
    name  = "application.path"
    value = var.helm_chart_path
  }

  set {
    name  = "application.namespace"
    value = "default"
  }

  depends_on = [
    helm_release.argocd
  ]
}
