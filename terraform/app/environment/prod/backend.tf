terraform {
  backend "s3" {
    bucket  = "sheva-shop"
    key     = "prod/terraform/remote-backend/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}