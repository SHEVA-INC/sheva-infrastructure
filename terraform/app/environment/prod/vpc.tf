locals {
  vpc_name = "${var.app_name}-${var.vpc_postfix}"

  subnet_config = {
    public   = { cidr_offset = 4, name_prefix = "public-subnet" }
    private  = { cidr_offset = 0, name_prefix = "private-subnet" }
    database = { cidr_offset = 8, name_prefix = "db-subnet" }
  }

  public_subnet_names   = [for az in local.availability_zones : "${local.subnet_config.public.name_prefix}-${az}"]
  private_subnet_names  = [for az in local.availability_zones : "${local.subnet_config.private.name_prefix}-${az}"]
  database_subnet_names = [for az in local.availability_zones : "${local.subnet_config.database.name_prefix}-${az}"]

  public_subnet_tags = {
    VPC = local.vpc_name
  }
  private_subnet_tags = {
    VPC = local.vpc_name
  }
  database_subnet_tags = {
    VPC = local.vpc_name
  }

  nacl_rules = {
    public_inbound = [
      { rule_number = 100, egress = false, protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 80, to_port = 80 },
      { rule_number = 110, egress = false, protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 443, to_port = 443 },
      { rule_number = 120, egress = false, protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 1024, to_port = 65535 }
    ]
    public_outbound = [
      { rule_number = 100, egress = true, protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 80, to_port = 80 },
      { rule_number = 110, egress = true, protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 443, to_port = 443 },
      { rule_number = 120, egress = true, protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 1024, to_port = 65535 }
    ]
    private_inbound = [
      { rule_number = 100, egress = false, protocol = "-1", rule_action = "allow", cidr_block = var.vpc_cidr, from_port = 0, to_port = 0 }
    ]
    private_outbound = [
      { rule_number = 100, egress = true, protocol = "-1", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 0, to_port = 0 }
    ]
    database_inbound = [
      { rule_number = 100, egress = false, protocol = "tcp", rule_action = "allow", cidr_block = var.vpc_cidr, from_port = 5432, to_port = 5432 }
    ]
    database_outbound = [
      { rule_number = 100, egress = true, protocol = "tcp", rule_action = "allow", cidr_block = var.vpc_cidr, from_port = 1024, to_port = 65535 }
    ]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.vpc_name
  cidr = var.vpc_cidr
  azs  = local.availability_zones

  enable_nat_gateway                        = true
  single_nat_gateway                        = true
  create_database_nat_gateway_route         = false
  create_database_subnet_route_table        = true
  create_elasticache_subnet_group           = false
  enable_flow_log                           = true
  create_flow_log_cloudwatch_iam_role       = true
  create_flow_log_cloudwatch_log_group      = true
  flow_log_cloudwatch_log_group_name_prefix = "/aws/vpc-flow-log/${local.vpc_name}"

  public_subnets   = [for k, v in local.availability_zones : cidrsubnet(var.vpc_cidr, 8, k + local.subnet_config.public.cidr_offset)]
  private_subnets  = [for k, v in local.availability_zones : cidrsubnet(var.vpc_cidr, 8, k + local.subnet_config.private.cidr_offset)]
  database_subnets = [for k, v in local.availability_zones : cidrsubnet(var.vpc_cidr, 8, k + local.subnet_config.database.cidr_offset)]

  public_subnet_names = local.public_subnet_names
  public_subnet_tags  = local.public_subnet_tags

  private_subnet_names = local.private_subnet_names
  private_subnet_tags  = local.private_subnet_tags

  database_subnet_names = local.database_subnet_names
  database_subnet_tags  = local.database_subnet_tags

  # public_dedicated_network_acl   = true
  # private_dedicated_network_acl  = true
  # database_dedicated_network_acl = true

  # public_inbound_acl_rules  = local.nacl_rules.public_inbound
  # public_outbound_acl_rules = local.nacl_rules.public_outbound
  # public_acl_tags = {
  #   Name = "${local.vpc_name}-public-acl"
  # }

  # private_inbound_acl_rules  = local.nacl_rules.private_inbound
  # private_outbound_acl_rules = local.nacl_rules.private_outbound
  # private_acl_tags = {
  #   Name = "${local.vpc_name}-private-acl"
  # }

  # database_inbound_acl_rules  = local.nacl_rules.database_inbound
  # database_outbound_acl_rules = local.nacl_rules.database_outbound
  # database_acl_tags = {
  #   Name = "${local.vpc_name}-database-acl"
  # }

  igw_tags = {
    Name = "${local.vpc_name}-igw"
  }

  vpc_flow_log_tags = {
    Name = "${var.app_name}-flow-logs"
  }

  vpc_tags = {
    Name = local.vpc_name
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.vpc_endpoints_security_group.security_group_id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.vpc_endpoints_security_group.security_group_id]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids
}