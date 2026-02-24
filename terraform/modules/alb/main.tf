variable "vpc_id" {}
variable "subnets" {}
variable "alb_sg" {}
variable "container_port" {}
variable "app_name" {}

resource "aws_lb" "app" {
  name               = "${var.app_name}-alb"
  load_balancer_type = "application"
  subnets            = var.subnets
  security_groups    = [var.alb_sg]
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.app_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
}

output "alb_dns" {
  value = aws_lb.app.dns_name
}
