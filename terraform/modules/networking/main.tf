data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "selected" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

locals {
  unique_subnets = values({
    for s in data.aws_subnet.selected :
    s.availability_zone => s.id
  })
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnets" {
  value = local.unique_subnets
}
