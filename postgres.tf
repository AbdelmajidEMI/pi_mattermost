resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "my-db-subnet-group"
  description = "Subnet group for the PostgreSQL database"
  subnet_ids  = [
    aws_subnet.db_subnets["1"].id,
    aws_subnet.db_subnets["2"].id,
    aws_subnet.db_subnets["3"].id
  ]

  tags = {
    Name = "my-db-subnet-group"
  }
}



resource "aws_db_instance" "postgres" {
  identifier              = "mattermost-postgres"
  engine                  = "postgres"
  engine_version          = "16.3"
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.postgres_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot     = true
  deletion_protection     = false
  # multi_az                = true  # Enable Multi-AZ for standby instance
  # backup_retention_period = 7   # Optional, adjust to your backup needs
  # maintenance_window      = "Sun:05:00-Sun:06:00"  # Optional, adjust to your maintenance window
  # storage_encrypted       = true  # Optional, enable encryption at rest

  tags = {
    Name = "Mattermost PostgreSQL"
  }
}

