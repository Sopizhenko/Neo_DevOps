terraform {
  backend "s3" {
    bucket         = "lesson-5-s3-back"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}