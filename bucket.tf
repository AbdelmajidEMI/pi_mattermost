# Create S3 bucket
resource "aws_s3_bucket" "mattermost_filestorage_bucket" {
  bucket = "${var.domaine}"

  tags = {
    Name        = "Mattermost"
    Environment = "Production"
  }
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.mattermost_Cluster.id  # Reference your VPC
  service_name      = "com.amazonaws.${var.region}.s3"  # S3 service endpoint
  route_table_ids   = [aws_route_table.private_app.id]  # Associate with the appropriate route tables

  tags = {
    Name = "Mattermost S3 Gateway Endpoint"
  }
}
