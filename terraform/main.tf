provider "aws" {
  region = var.region
}

module "networking" {
  source = "./modules"
}

module "security" {
  source         = "./modules"
  vpc_id         = module.networking.vpc_id
  container_port = var.container_port
  app_name       = var.app_name
}

module "alb" {
  source          = "./modules"
  vpc_id          = module.networking.vpc_id
  subnets         = module.networking.subnets
  alb_sg          = module.security.alb_sg
  container_port  = var.container_port
  app_name        = var.app_name
}

module "ecs" {
  source            = "./modules"
  subnets           = module.networking.subnets
  ecs_sg            = module.security.ecs_sg
  target_group_arn  = module.alb.target_group_arn
  container_port    = var.container_port
  ecr_image_url     = var.ecr_image_url
  app_name          = var.app_name
  region            = var.region
}
