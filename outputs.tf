#-------------Backend-----------------

output "s3_backend_bucket_name" {
  value = module.s3_backend.bucket_name
}

#-------------VPC-----------------

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

#-------------EKS-----------------

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

#-------------ECR-----------------

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = module.ecr.repository_name
}

#-------------Jenkins-----------------

output "jenkins_url" {
  description = "Jenkins URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_user" {
  description = "Jenkins admin username"
  value       = module.jenkins.jenkins_admin_user
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}

#-------------Argo CD-----------------

output "argocd_url" {
  description = "Argo CD URL"
  value       = module.argo_cd.argocd_url
}

output "argocd_admin_password" {
  description = "Argo CD initial admin password"
  value       = module.argo_cd.argocd_admin_password
  sensitive   = true
}

#-------------RDS PostgreSQL-----------------

output "postgres_endpoint" {
  description = "PostgreSQL RDS endpoint"
  value       = module.rds_postgres.endpoint
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = module.rds_postgres.database_name
}

output "postgres_master_username" {
  description = "PostgreSQL master username"
  value       = module.rds_postgres.master_username
  sensitive   = true
}

output "postgres_port" {
  description = "PostgreSQL port"
  value       = module.rds_postgres.port
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string"
  value       = module.rds_postgres.connection_string
  sensitive   = true
}

#-------------RDS Aurora MySQL-----------------

output "aurora_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = module.rds_aurora.endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = module.rds_aurora.reader_endpoint
}

output "aurora_database_name" {
  description = "Aurora database name"
  value       = module.rds_aurora.database_name
}

output "aurora_master_username" {
  description = "Aurora master username"
  value       = module.rds_aurora.master_username
  sensitive   = true
}

output "aurora_port" {
  description = "Aurora port"
  value       = module.rds_aurora.port
}

output "aurora_connection_string" {
  description = "Aurora connection string"
  value       = module.rds_aurora.connection_string
  sensitive   = true
}
