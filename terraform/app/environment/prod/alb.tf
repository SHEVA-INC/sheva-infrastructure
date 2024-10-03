locals {
  alb_name = "${var.app_name}-${var.alb_postfix}"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = local.alb_name

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    },
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    },
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      redirect = {
        port        = 443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = aws_acm_certificate.alb.arn

      forward = {
        target_group_key = "ecs"
      }

      depends_on = [aws_acm_certificate.alb]
    }
  }

  target_groups = {
    ecs = {
      backend_protocol                  = "HTTP"
      backend_port                      = var.ecs_container_port.ui_container
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 60
        matcher             = "200"
        path                = "/home/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 10
        unhealthy_threshold = 2
      }

      create_attachment = false
    }
  }

  tags = {
    Name = local.alb_name
  }
}

resource "aws_lb_listener_certificate" "this" {
  listener_arn    = module.alb.listeners.https.arn
  certificate_arn = aws_acm_certificate.alb.arn

  depends_on = [aws_acm_certificate_validation.this]
}