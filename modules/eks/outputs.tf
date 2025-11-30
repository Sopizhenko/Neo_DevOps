output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "node_group_name" {
  value = aws_eks_node_group.this.node_group_name
}

output "node_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

