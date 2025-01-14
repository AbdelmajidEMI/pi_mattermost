resource "aws_lb" "mattermost_alb" {
  name               = "mattermost-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.web_subnets : subnet.id] 

  idle_timeout = 300

  tags = {
    Name = "Mattermost ALB"
  }
}

resource "aws_lb_listener" "mattermost_listener" {
  load_balancer_arn = aws_lb.mattermost_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.mattermost_acm_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mattermost_tg.arn
  }
}

resource "aws_lb_target_group" "mattermost_tg" {
  name     = "mattermost"
  port     = 8065
  protocol = "HTTP"
  vpc_id   = aws_vpc.mattermost_Cluster.id
  
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  # stickiness {
  #   type            = "lb_cookie"
  #   enabled         = true
  #   cookie_duration = 86400 # 1 day
  # }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_to_target_group" {
  autoscaling_group_name = aws_autoscaling_group.mattermost_asg.id
  lb_target_group_arn    = aws_lb_target_group.mattermost_tg.arn
}