resource "aws_security_group" "postgres_sg" {
  name        = "postgres-sg"
  description = "Security group for PostgreSQL database"
  vpc_id      = aws_vpc.mattermost_Cluster.id

  ingress {
    description = "Allow Postgres from jump box and application servers"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_security_group.app_sg.id        # Allow connections from the app SG (to be created later)
    ]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Mattermost PostgreSQL SG"
  }
}


resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.mattermost_Cluster.id

  ingress {
    description = "Allow Gossip access (TCP)"
    from_port   = 8074
    to_port     = 8074
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow Gossip access (UDP)"
    from_port   = 8074
    to_port     = 8074
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "Allow access to Mattermost"
    from_port   = 8065
    to_port     = 8065
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Application SG"
  }
}



resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.mattermost_Cluster.id

  

  ingress {
    description = "Allow access to Mattermost"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Application SG"
  }
}
