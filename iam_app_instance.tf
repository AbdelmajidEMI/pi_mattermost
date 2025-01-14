# Define IAM Role for EC2 with SSM and S3 access
resource "aws_iam_role" "ssm_role_mattermost" {
  name = "ssm-role_mattermost"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  # Inline policy to grant SSM and S3 bucket access
  inline_policy {
    name = "SSMAndS3AccessPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["ssm:GetParameter", "ssm:DescribeParameters"]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject"
          ]
          Resource = "${aws_s3_bucket.mattermost_filestorage_bucket.arn}/*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ],
          "Resource": "${aws_s3_bucket.mattermost_filestorage_bucket.arn}",
        }
      ]
    })
  }
}

# Create IAM instance profile for the role
resource "aws_iam_instance_profile" "instance_profile_mattermost" {
  role = aws_iam_role.ssm_role_mattermost.name
}

# Attach AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role_mattermost.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
