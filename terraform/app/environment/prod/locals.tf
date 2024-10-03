locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  environment        = basename(abspath(path.cwd))
}