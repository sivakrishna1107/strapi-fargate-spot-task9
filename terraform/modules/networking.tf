data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnets" {
  value = data.aws_subnets.default.ids
}
