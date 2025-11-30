# Outputs that work for both RDS and Aurora

# Database endpoint
output "endpoint" {
  description = "Database endpoint (writer endpoint for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].endpoint
}

# Database reader endpoint (Aurora only)
output "reader_endpoint" {
  description = "Aurora cluster reader endpoint (empty for standard RDS)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : ""
}

# Database port
output "port" {
  description = "Database port"
  value       = var.port
}

# Database name
output "database_name" {
  description = "Name of the database"
  value       = var.database_name
}

# Master username
output "master_username" {
  description = "Master username"
  value       = var.master_username
  sensitive   = true
}

# Database identifier
output "identifier" {
  description = "Database identifier"
  value       = var.identifier
}

# Database type
output "database_type" {
  description = "Type of database (RDS or Aurora)"
  value       = var.use_aurora ? "Aurora" : "RDS"
}

# Engine
output "engine" {
  description = "Database engine"
  value       = var.engine
}

# Engine version
output "engine_version" {
  description = "Database engine version"
  value       = var.engine_version
}

# Security group ID
output "security_group_id" {
  description = "Security group ID for the database"
  value       = aws_security_group.this.id
}

# DB subnet group name
output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.this.name
}

# RDS instance ARN
output "rds_instance_arn" {
  description = "ARN of the RDS instance (empty for Aurora)"
  value       = var.use_aurora ? "" : aws_db_instance.this[0].arn
}

# Aurora cluster ARN
output "aurora_cluster_arn" {
  description = "ARN of the Aurora cluster (empty for standard RDS)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].arn : ""
}

# Aurora cluster identifier
output "aurora_cluster_id" {
  description = "Aurora cluster identifier (empty for standard RDS)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].id : ""
}

# Aurora instance identifiers
output "aurora_instance_ids" {
  description = "List of Aurora instance identifiers (empty for standard RDS)"
  value       = var.use_aurora ? aws_rds_cluster_instance.this[*].id : []
}

# Connection string helper
output "connection_string" {
  description = "Connection string example (without password)"
  value = var.use_aurora ? (
    var.engine == "aurora-postgresql" || var.engine == "postgres" ?
    "postgresql://${var.master_username}:PASSWORD@${aws_rds_cluster.this[0].endpoint}:${var.port}/${var.database_name}" :
    "mysql://${var.master_username}:PASSWORD@${aws_rds_cluster.this[0].endpoint}:${var.port}/${var.database_name}"
    ) : (
    var.engine == "postgres" ?
    "postgresql://${var.master_username}:PASSWORD@${aws_db_instance.this[0].endpoint}/${var.database_name}" :
    "mysql://${var.master_username}:PASSWORD@${aws_db_instance.this[0].endpoint}/${var.database_name}"
  )
  sensitive = true
}
