variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
}

variable "region" {
  description = "AWS region for S3 bucket and DynamoDB table"
  type        = string
  default     = "us-west-2"
}
