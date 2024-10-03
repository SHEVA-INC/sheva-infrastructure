locals {
  api_efs_volume_name         = "${var.app_name}-${var.api_efs_volume_postfix}"
  api_efs_security_group_name = "${var.app_name}-${var.api_efs_security_group_postfix}"
}

module "api_efs_volume" {
  source = "terraform-aws-modules/efs/aws"

  name           = local.api_efs_volume_name
  creation_token = local.api_efs_volume_name
  encrypted      = false

  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  attach_policy                      = true
  bypass_policy_lockout_safety_check = false
  policy_statements = [
    {
      sid = "ECSTasksReadWriteAccess"
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite"
      ]
      principals = [
        {
          type        = "AWS"
          identifiers = [module.ecs_api_service.task_exec_iam_role_arn]
        }
      ]
    }
  ]

  mount_targets                  = { for k, v in zipmap(local.availability_zones, module.vpc.private_subnets) : k => { subnet_id = v } }
  security_group_name            = local.api_efs_security_group_name
  security_group_use_name_prefix = true
  security_group_description     = "API Storage (EFS) security group"
  security_group_vpc_id          = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      # using the default configuration for EFS/NFS (TCP port 2049 and ingress)
      # https://github.com/terraform-aws-modules/terraform-aws-efs/blob/master/main.tf
      description              = "NFS ingress from VPC private subnets"
      source_security_group_id = module.api_service_security_group.security_group_id
    }
  }

  access_points = {
    django = {
      posix_user = {
        gid = 1001
        uid = 1001
      }
      root_directory = {
        path = "/home/django"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
    }
  }

  enable_backup_policy             = true
  create_replication_configuration = true

  replication_configuration_destination = {
    region = var.region
  }

  tags = {
    Name = local.api_efs_volume_name
  }
}