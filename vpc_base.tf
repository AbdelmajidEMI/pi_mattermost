# VPC
resource "aws_vpc" "mattermost_Cluster" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Mattermost Cluster VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mattermost_Cluster.id

  tags = {
    Name = "Mattermost IGW"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.mattermost_Cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Mattermost Public Route Table"
  }
}

# Private Route Table for Database Subnets (No Internet Access)
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.mattermost_Cluster.id

  tags = {
    Name = "Mattermost Private Route Table - DB Subnets"
  }
}

# Private Route Table for Application Subnets (Internet Access via NAT Gateway)
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.mattermost_Cluster.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_nat.id
  }

  tags = {
    Name = "Mattermost Private Route Table - App Subnets"
  }
}

# Subnets
resource "aws_subnet" "db_subnets" {
  for_each = var.subnets

  vpc_id            = aws_vpc.mattermost_Cluster.id
  cidr_block        = each.value.postgres
  availability_zone = data.aws_availability_zones.available.names[each.key - 1]
  map_public_ip_on_launch = false

  tags = {
    Name = "Mattermost Private Subnet - Zone ${each.key} - Postgres"
  }
}

resource "aws_subnet" "web_subnets" {
  for_each = var.subnets

  vpc_id            = aws_vpc.mattermost_Cluster.id
  cidr_block        = each.value.web
  availability_zone = data.aws_availability_zones.available.names[each.key - 1]
  map_public_ip_on_launch = true

  tags = {
    Name = "Mattermost Public Subnet - Zone ${each.key} - Web"
  }
}

resource "aws_subnet" "app_subnets" {
  for_each = var.subnets

  vpc_id            = aws_vpc.mattermost_Cluster.id
  cidr_block        = each.value.app
  availability_zone = data.aws_availability_zones.available.names[each.key - 1]
  map_public_ip_on_launch = false

  tags = {
    Name = "Mattermost Private Subnet - Zone ${each.key} - App"
  }
}


# Route Table Associations
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.web_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_db" {
  for_each = aws_subnet.db_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.app_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app.id
}

# Availability Zones Data Source
data "aws_availability_zones" "available" {}
