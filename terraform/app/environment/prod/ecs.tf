locals {
  ecs_cluster_name = "${var.app_name}-${var.ecs_cluster_postfix}"

  api_service_discovery_namespace = join(".", [
    var.ecs_service_name.api_service,
    var.service_discovery_namespace
  ])
  api_base_url = "http://${local.api_service_discovery_namespace}:${var.ecs_container_port.api_container}"
  api_environment_variables = {
    POSTGRES_NAME      = data.aws_ssm_parameter.params["postgres_name"].value
    POSTGRES_USER      = data.aws_ssm_parameter.params["postgres_user"].value
    POSTGRES_HOST      = element(split(":", module.rds.db_instance_endpoint), 0)
    POSTGRES_PASSWORD  = data.aws_ssm_parameter.params["postgres_password"].value
    SECRET_KEY         = data.aws_ssm_parameter.params["secret_key"].value
    SUPERUSER_NAME     = data.aws_ssm_parameter.params["superuser_name"].value
    SUPERUSER_EMAIL    = data.aws_ssm_parameter.params["superuser_email"].value
    SUPERUSER_PASSWORD = data.aws_ssm_parameter.params["superuser_password"].value
    TELEGRAM_BOT_TOKEN = data.aws_ssm_parameter.params["telegram_bot_token"].value
    TELEGRAM_CHAT_ID   = data.aws_ssm_parameter.params["telegram_chat_id"].value
    MONO_TOKEN         = data.aws_ssm_parameter.params["mono_token"].value
  }

  ui_environment_variables = {
    API_URL              = "${local.api_base_url}/api/"
    MEDIA_URL            = "${local.api_base_url}/media/"
    NOVA_POST_SECRET_KEY = data.aws_ssm_parameter.params["nova_post_secret_key"].value
  }
}

module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  cluster_name = local.ecs_cluster_name

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/${local.ecs_cluster_name}"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  tags = {
    Name = local.ecs_cluster_name
  }
}

resource "aws_service_discovery_private_dns_namespace" "api" {
  name        = var.service_discovery_namespace
  description = "Private dns namespace for API service discovery"
  vpc         = module.vpc.vpc_id

  tags = {
    Name = var.service_discovery_namespace
  }
}

resource "aws_service_discovery_service" "api" {
  name = var.ecs_service_name.api_service

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.api.id

    dns_records {
      ttl  = 60
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name = var.ecs_service_name.api_service
  }
}

module "ecs_api_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = var.ecs_service_name.api_service
  cluster_arn = module.ecs_cluster.arn

  cpu    = 256
  memory = 512

  container_definitions = {
    (var.ecs_container_name.api_container) = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = data.aws_ecr_image.images["api"].image_uri
      port_mappings = [
        {
          name          = var.ecs_container_name.api_container
          containerPort = var.ecs_container_port.api_container
          protocol      = "tcp"
        }
      ]

      readonly_root_filesystem = false

      environment = [
        for name, value in local.api_environment_variables : {
          name  = name
          value = value
        }
      ]

      mount_points = [
        {
          sourceVolume  = "efs"
          containerPath = "/home/django/app/media"
          readOnly      = false
        }
      ]
    }
  }

  service_registries = {
    registry_arn   = aws_service_discovery_service.api.arn
    container_name = var.ecs_container_name.api_container
  }

  subnet_ids            = module.vpc.private_subnets
  create_security_group = false
  security_group_ids    = [module.api_service_security_group.security_group_id]

  volume = {
    efs = {
      name = "efs"
      efs_volume_configuration = {
        file_system_id     = module.api_efs_volume.id
        transit_encryption = "ENABLED"
        authorization_config = {
          access_point_id = module.api_efs_volume.access_points["django"].id
          iam             = "ENABLED"
        }
      }
    }
  }

  task_tags = {
    Name = var.ecs_container_name.api_container
  }

  service_tags = {
    Name = var.ecs_service_name.api_service
  }

  tags = {
    Name    = var.ecs_service_name.api_service
    Cluster = local.ecs_cluster_name
  }
}

module "ecs_ui_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = var.ecs_service_name.ui_service
  cluster_arn = module.ecs_cluster.arn

  cpu    = 256
  memory = 512

  container_definitions = {
    (var.ecs_container_name.ui_container) = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = data.aws_ecr_image.images["ui"].image_uri
      port_mappings = [
        {
          name          = var.ecs_container_name.ui_container
          containerPort = var.ecs_container_port.ui_container
          protocol      = "tcp"
        }
      ]

      readonly_root_filesystem = false
      environment = [
        for name, value in local.ui_environment_variables : {
          name  = name
          value = value
        }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["ecs"].arn
      container_name   = var.ecs_container_name.ui_container
      container_port   = var.ecs_container_port.ui_container
    }
  }

  subnet_ids            = module.vpc.private_subnets
  create_security_group = false
  security_group_ids    = [module.ui_service_security_group.security_group_id]

  depends_on = [module.ecs_api_service]

  task_tags = {
    Name = var.ecs_container_name.ui_container
  }

  service_tags = {
    Name = var.ecs_service_name.ui_service
  }

  tags = {
    Name    = var.ecs_service_name.ui_service
    Cluster = local.ecs_cluster_name
  }
}