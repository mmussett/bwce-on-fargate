

### ALB


resource "aws_alb" "main" {
  name            = "mm-bwce-fargate-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.lb.id]
  subnets         = aws_subnet.public.*.id

      tags = {
      Name = "mm-bwce-fargate-alb"
      User = var.user
  }
}

resource "aws_alb_target_group" "app" {
  name        = "mm-bwce-fargate-app-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path = "/_ping/"
    port = var.healthcheck_port
    protocol = "HTTP"
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
    matcher = "200"  # has to be HTTP 200 or fails
  }

  tags = {
      Name = "mm-bwce-fargate-alb-tg"
      User = var.user
  }

}


# Setup a Listener with Listener Rules that allow you to forward the requests to appropriate targets in one or more target groups.
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.arn
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "listener_rule_front_end" {
  depends_on = [aws_alb_target_group.app]
  listener_arn = aws_alb_listener.front_end.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.app.arn
  }
  condition {
    path_pattern {
      values = ["/trips/*"]
    }
  }

}


