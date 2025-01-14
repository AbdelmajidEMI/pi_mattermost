variable "region" {
  type        = string
  default     = "us-east-1"
}

variable "domaine" {
  type = string
  default = "www.devopsmajid.com"
}


variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "List of subnets with their respective CIDR blocks"
  type = map(object({
    postgres = string
    web      = string
    app      = string
  }))
  default = {
    1 = {
      postgres = "10.0.1.0/24"
      web      = "10.0.4.0/24"
      app      = "10.0.7.0/24"
    }
    2 = {
      postgres = "10.0.2.0/24"
      web      = "10.0.5.0/24"
      app      = "10.0.8.0/24"
    }
    3 = {
      postgres = "10.0.3.0/24"
      web      = "10.0.6.0/24"
      app      = "10.0.9.0/24"
    }
  }
}




variable "db_name" {
  description = "The name of the PostgreSQL database"
  default     = "mattermost"
}

variable "db_username" {
  description = "The master username for the PostgreSQL database"
  default     = "abood"
}

variable "db_password" {
  description = "The master password for the PostgreSQL database"
  default     = "00000000" # Replace this with a secure value
  sensitive   = true
}



variable "db_instance_class" {
  description = "The instance type for the RDS instance"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "The allocated storage in GB"
  default     = 20
}

variable "mattermost_instance_type" {
  description = "Mattermost instance type"
  default     = "t2.micro"
}

variable "desired_capacity" {
  default = 2
}


variable "ROUTE53_ZONE_ID" {
  description = "ROUTE53 ZONE ID"
  default     = "Z03957461EWHN4U6OYYIZ"
}



data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"]  # This is the Canonical owner ID for Ubuntu images.
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]  # Ubuntu 22.04 LTS
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]  # or "arm64" for ARM architecture
  }
}

