module "rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier                     = data.aws_ssm_parameter.params["postgres_name"].value
  instance_use_identifier_prefix = false

  create_db_option_group    = true
  create_db_parameter_group = true

  engine               = "postgres"
  engine_version       = "16.3"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = "db.t4g.micro"

  allocated_storage = 20
  storage_encrypted = false

  manage_master_user_password = false
  db_name                     = data.aws_ssm_parameter.params["postgres_name"].value
  username                    = data.aws_ssm_parameter.params["postgres_user"].value
  password                    = data.aws_ssm_parameter.params["postgres_password"].value
  port                        = 5432

  db_subnet_group_name     = module.vpc.database_subnet_group_name
  vpc_security_group_ids   = [module.db_security_group.security_group_id]
  maintenance_window       = "Mon:00:00-Mon:03:00"
  backup_window            = "03:00-06:00"
  backup_retention_period  = 0
  delete_automated_backups = false

  parameters = [
    {
      name  = "rds.force_ssl"
      value = "0"
    }
  ]
}