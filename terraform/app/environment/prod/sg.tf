locals {
  db_security_group_name            = "${var.app_name}-${var.db_security_group_postfix}"
  vpc_endpoints_security_group_name = "${var.app_name}-${var.vpc_endpoints_security_group_postfix}"
  ui_service_security_group_name    = "${var.app_name}-${var.ui_service_security_group_postfix}"
  api_service_security_group_name   = "${var.app_name}-${var.api_service_security_group_postfix}"

  all_ports = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all outbound traffic"
    cidr_blocks = "0.0.0.0/0"
  }

  vpc_endpoint_port = {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "VPC Endpoints Service Port"
  }
}

module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = local.db_security_group_name
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "PostgreSQL from API"
      source_security_group_id = module.api_service_security_group.security_group_id
    }
  ]

  egress_with_cidr_blocks = [local.all_ports]

  tags = {
    Name = local.db_security_group_name
  }
}

module "vpc_endpoints_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "${var.app_name}-${var.vpc_endpoints_security_group_postfix}"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    merge(local.vpc_endpoint_port, {
      description = "Access from ECS"
      cidr_blocks = module.vpc.vpc_cidr_block
    })
  ]

  egress_with_cidr_blocks = [local.all_ports]

  tags = {
    Name = local.vpc_endpoints_security_group_name
  }
}

module "ui_service_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = local.ui_service_security_group_name
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = var.ecs_container_port.ui_container
      to_port                  = var.ecs_container_port.ui_container
      protocol                 = "tcp"
      description              = "ALB Service Port"
      source_security_group_id = module.alb.security_group_id
    },
    merge(local.vpc_endpoint_port, {
      source_security_group_id = module.vpc_endpoints_security_group.security_group_id
    })
  ]

  # egress_with_source_security_group_id = [
  #   {
  #     from_port                = var.ecs_container_port.api_container
  #     to_port                  = var.ecs_container_port.api_container
  #     protocol                 = "tcp"
  #     description              = "API Port"
  #     source_security_group_id = module.api_service_security_group.security_group_id
  #   }
  # ]

  egress_with_cidr_blocks = [local.all_ports]

  tags = {
    Name = local.ui_service_security_group_name
  }
}

module "api_service_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = local.api_service_security_group_name
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = var.ecs_container_port.api_container
      to_port                  = var.ecs_container_port.api_container
      protocol                 = "tcp"
      description              = "UI Service Port"
      source_security_group_id = module.ui_service_security_group.security_group_id
    },
    merge(local.vpc_endpoint_port, {
      source_security_group_id = module.vpc_endpoints_security_group.security_group_id
    })
  ]

  # egress_with_source_security_group_id = [
  #   {
  #     rule                     = "postgresql-tcp"
  #     description              = "RDS Port"
  #     source_security_group_id = module.db_security_group.security_group_id
  #   },
  #   {
  #     from_port                = 2049
  #     to_port                  = 2049
  #     protocol                 = "tcp"
  #     description              = "EFS Port"
  #     source_security_group_id = module.api_efs_volume.security_group_id
  #   }
  # ]

  egress_with_cidr_blocks = [local.all_ports]

  tags = {
    Name = local.api_service_security_group_name
  }
}