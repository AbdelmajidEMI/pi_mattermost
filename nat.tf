# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "NAT Gateway Elastic IP"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "app_nat" {
  allocation_id     = aws_eip.nat.id
  subnet_id         = aws_subnet.web_subnets["2"].id # Use the first public subnet
  connectivity_type = "public"

  tags = {
    Name = "NAT Gateway"
  }
}
