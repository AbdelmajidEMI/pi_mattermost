# Store the PostgreSQL connection string in Parameter Store
resource "aws_ssm_parameter" "db_connection_string" {
  name        = "/mattermost/db_connection"
  type        = "SecureString"
  value       = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres.endpoint}/${var.db_name}"
  description = "PostgreSQL connection string for Mattermost"
  tags = {
    Application = "Mattermost"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Store the domain name in Parameter Store
resource "aws_ssm_parameter" "domain_name" {
  name        = "/mattermost/domain"
  type        = "String"
  value       = "${var.domaine}"
  description = "Domain name for Mattermost"
  tags = {
    Application = "Mattermost"
  }
  lifecycle {
    create_before_destroy = true
  }
}
