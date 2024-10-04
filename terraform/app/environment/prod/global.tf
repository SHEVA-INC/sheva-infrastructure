locals {
  ssm_prefix = "/${var.app_name}/${local.environment}"

  ssm_parameters = {
    nova_post_secret_key = "NOVA_POST_SECRET_KEY"
    postgres_name        = "POSTGRES_NAME"
    postgres_password    = "POSTGRES_PASSWORD"
    postgres_user        = "POSTGRES_USER"
    secret_key           = "SECRET_KEY"
    telegram_bot_token   = "TELEGRAM_BOT_TOKEN"
    telegram_chat_id     = "TELEGRAM_CHAT_ID"
    superuser_name       = "SUPERUSER_NAME"
    superuser_email      = "SUPERUSER_EMAIL"
    superuser_password   = "SUPERUSER_PASSWORD"
    mono_token           = "MONO_TOKEN"
  }

  ecr_images = {
    api = {
      repository_name = "sheva-api"
      image_tag       = "f1242dd7caaa232d85ec930324d11329036fc61f"
    }
    ui = {
      repository_name = "sheva-ui"
      image_tag       = "52262e023bef2bd9c3bcf54f05ed7f97383ce37b"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

data "aws_ssm_parameter" "params" {
  for_each = local.ssm_parameters
  name     = "${local.ssm_prefix}/${each.value}"
}

data "aws_ecr_image" "images" {
  for_each        = local.ecr_images
  repository_name = each.value.repository_name
  image_tag       = each.value.image_tag
}
