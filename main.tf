terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "lesson-5-s3-back"
  region      = "us-west-2"

}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-5-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-5-ecr"
  scan_on_push = true
}

# Модуль EKS — кластер в існуючій VPC
module "eks" {
  source             = "./modules/eks"
  cluster_name       = "lesson-7-eks"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  desired_size = 2
  min_size     = 2
  max_size     = 6

  instance_types = ["t2.micro"]
}

# Модуль Jenkins
module "jenkins" {
  source = "./modules/jenkins"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate

  namespace              = "jenkins"
  jenkins_chart_version  = "5.1.27"
  jenkins_admin_user     = "admin"
  jenkins_admin_password = "admin123"

  ecr_repository_url = module.ecr.repository_url
  aws_region         = "us-west-2"
}

# Модуль Argo CD
module "argo_cd" {
  source = "./modules/argo_cd"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate

  namespace              = "argocd"
  argocd_chart_version   = "7.7.5"
  github_repo_url        = "https://github.com/Sopizhenko/Neo_DevOps.git"
  github_target_revision = "lesson-7"
  helm_chart_path        = "charts/django-app"
}

# Модуль RDS - PostgreSQL (standard RDS)
module "rds_postgres" {
  source = "./modules/rds"

  identifier     = "lesson-postgres"
  use_aurora     = false
  engine         = "postgres"
  engine_version = "14.7"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  database_name   = "myappdb"
  master_username = "dbadmin"
  master_password = "ChangeMe123!"  # Should use AWS Secrets Manager in production
  port            = 5432

  multi_az = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Allow access from EKS nodes
  allowed_security_group_ids = [module.eks.node_security_group_id]

  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true

  parameter_group_family = "postgres14"
  parameters = [
    {
      name  = "max_connections"
      value = "100"
    },
    {
      name  = "shared_buffers"
      value = "{DBInstanceClassMemory/32768}"
    },
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Environment = "lesson-8-9"
    Project     = "Neo-DevOps"
    Type        = "PostgreSQL-RDS"
  }
}

# Модуль RDS - Aurora MySQL
module "rds_aurora" {
  source = "./modules/rds"

  identifier     = "lesson-aurora"
  use_aurora     = true
  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.02.0"
  instance_class = "db.t3.small"

  database_name   = "auroradb"
  master_username = "auroramin"
  master_password = "AuroraPass123!"  # Should use AWS Secrets Manager in production
  port            = 3306

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Allow access from EKS nodes
  allowed_security_group_ids = [module.eks.node_security_group_id]

  aurora_instance_count = 2

  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true

  parameter_group_family = "aurora-mysql8.0"
  parameters = [
    {
      name  = "max_connections"
      value = "150"
    },
    {
      name  = "innodb_buffer_pool_size"
      value = "{DBInstanceClassMemory*3/4}"
    }
  ]

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  tags = {
    Environment = "lesson-8-9"
    Project     = "Neo-DevOps"
    Type        = "Aurora-MySQL"
  }
}

# Модуль Monitoring - Prometheus & Grafana
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate

  namespace                = "monitoring"
  prometheus_chart_version = "55.5.0"
  prometheus_retention     = "15d"
  prometheus_storage_size  = "50Gi"
  grafana_admin_password   = "admin123"  # Should use AWS Secrets Manager in production
  enable_django_monitoring = true
}
