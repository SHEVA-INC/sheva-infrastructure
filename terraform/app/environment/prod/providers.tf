provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project      = var.app_name
      Environment  = local.environment
      Repository   = var.repository_name
      Organization = var.organization_name
      Owner        = var.owner_name
      ManagedBy    = "Terraform"
    }
  }
}