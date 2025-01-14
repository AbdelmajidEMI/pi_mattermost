
# JVB boostraping
resource "aws_launch_template" "mattermost_template" {
  name_prefix     = "mattermost-template-"
  image_id        = data.aws_ami.ubuntu_22_04.id
  instance_type   = var.mattermost_instance_type
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  instance_initiated_shutdown_behavior = "terminate"
  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile_mattermost.name
  }


  # User data to install AWS CLI, psql (PostgreSQL client), and fetch from Parameter Store
  user_data = base64encode(file("${path.module}/files/setup_mattermost.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Mattermost-Instance"
    }
  }
}

resource "aws_autoscaling_group" "mattermost_asg" {
  name = "mattermost_asg"

  launch_template {
    id      = aws_launch_template.mattermost_template.id
    version = "$Latest"
  }

  # Multiple Subnets
  vpc_zone_identifier = flatten([for subnet in aws_subnet.app_subnets : subnet.id])

  min_size           = 1
  max_size           = 2
  desired_capacity   = var.desired_capacity

  tag {
    key                 = "Name"
    value               = "Mattermost"
    propagate_at_launch = true
  }

  # Health check configuration: Using EC2
  health_check_type          = "EC2"
  health_check_grace_period  = 120

  depends_on = [aws_ssm_parameter.db_connection_string, aws_db_instance.postgres]
}
