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
