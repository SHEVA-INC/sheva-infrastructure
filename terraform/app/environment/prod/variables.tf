### Global Variables ###
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "sheva-shop"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.app_name))
    error_message = "The app_name must contain only alphanumeric characters and hyphens."
  }
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^us-(east|west)-[1-2]$", var.region))
    error_message = "The region must be a valid AWS US region (us-east-1, us-east-2, us-west-1, us-west-2)."
  }
}

variable "repository_name" {
  description = "The name of the repository containing the infrastructure code"
  type        = string
  default     = "sheva-infrastructure"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.repository_name))
    error_message = "The repository_name must contain only alphanumeric characters and hyphens."
  }
}

variable "organization_name" {
  description = "The name of the organization"
  type        = string
  default     = "SHEVA INC"

  validation {
    condition     = can(regex("^[a-zA-Z0-9 ]+$", var.organization_name))
    error_message = "The organization_name must contain only alphanumeric characters and spaces."
  }
}

variable "owner_name" {
  description = "The name of the owner responsible for this infrastructure"
  type        = string
  default     = "Stanislav Zabarylo"

  validation {
    condition     = can(regex("^[a-zA-Z ]+$", var.owner_name))
    error_message = "The owner_name must contain only letters and spaces."
  }
}

### VPC Variables ###
variable "vpc_postfix" {
  description = "Postfix of the VPC"
  type        = string
  default     = "vpc"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.vpc_postfix))
    error_message = "The vpc_postfix must contain only alphanumeric characters and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/([0-9]{1,2}))?$", var.vpc_cidr))
    error_message = "The vpc_cidr must be a valid IPv4 CIDR block."
  }
}

### ALB Variables ###
variable "alb_postfix" {
  description = "Postfix of the ALB"
  type        = string
  default     = "alb"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.alb_postfix))
    error_message = "The alb_postfix must contain only alphanumeric characters and hyphens."
  }
}

### ECS Variables ###
variable "ecs_cluster_postfix" {
  description = "Postfix of the ECS cluster"
  type        = string
  default     = "ecs"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.ecs_cluster_postfix))
    error_message = "The ecs_cluster_postfix must contain only alphanumeric characters and hyphens."
  }
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = map(string)
  default = {
    "ui_service"  = "ui-service"
    "api_service" = "api-service"
  }
}

variable "ecs_container_name" {
  description = "Name of the ECS container"
  type        = map(string)
  default = {
    "ui_container"  = "ui-container"
    "api_container" = "api-container"
  }
}

variable "ecs_container_port" {
  description = "Port number for the ECS container"
  type        = map(number)
  default = {
    "ui_container"  = 80
    "api_container" = 8000
  }
}

### Route53 Variables ###
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "sheva-shop.com"
}

variable "service_discovery_namespace" {
  description = "Service discovery namespace for the application"
  type        = string
  default     = "sheva-shop.local"
}

### Security Groups Variables ###
variable "db_security_group_postfix" {
  description = "Postfix of the database security group"
  type        = string
  default     = "db-sg"
}

variable "vpc_endpoints_security_group_postfix" {
  description = "Postfix of the VPC endpoints security group"
  type        = string
  default     = "vpc-endpoints-sg"
}

variable "api_service_security_group_postfix" {
  description = "Postfix of the API service security group"
  type        = string
  default     = "api-service-sg"
}

variable "ui_service_security_group_postfix" {
  description = "Postfix of the API service security group"
  type        = string
  default     = "ui-service-sg"
}

variable "api_efs_security_group_postfix" {
  default = "api-service-efs-sg"
}

### EFS Variables ###
variable "api_efs_volume_postfix" {
  default = "api-service-volume"
}