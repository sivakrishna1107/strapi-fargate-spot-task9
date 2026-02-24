variable "region" { default = "us-east-1" }
variable "app_name" { default = "strapi-app" }
variable "container_port" { default = 1337 }

variable "ecr_image_url" {
  default = "123456789012.dkr.ecr.us-east-1.amazonaws.com/strapi:latest"
}
