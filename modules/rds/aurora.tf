# Aurora Cluster (created only when use_aurora = true)
resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = var.identifier

  # Engine configuration
  engine         = var.engine
  engine_version = var.engine_version
  engine_mode    = "provisioned"

  # Database configuration
  database_name   = var.database_name
  master_username = var.master_username
  master_password = var.master_password
  port            = var.port

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  # Parameter groups
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].name

  # Backup configuration
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Protection
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Storage encryption
  storage_encrypted = true

  # Copy tags to snapshots
  copy_tags_to_snapshot = true

  # Apply changes immediately (can be set to false for production)
  apply_immediately = false

  tags = merge(
    var.tags,
    {
      Name = var.identifier
      Type = "Aurora"
    }
  )
}

# Aurora Cluster Instances
resource "aws_rds_cluster_instance" "this" {
  count = var.use_aurora ? var.aurora_instance_count : 0

  identifier         = "${var.identifier}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this[0].id

  # Engine configuration
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Parameter group
  db_parameter_group_name = aws_db_parameter_group.aurora_instance[0].name

  # Monitoring
  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

  # Automatic minor version upgrades
  auto_minor_version_upgrade = true

  # Public access
  publicly_accessible = false

  # Copy tags from cluster
  copy_tags_to_snapshot = true

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-instance-${count.index + 1}"
      Type = "Aurora-Instance"
    }
  )
}
