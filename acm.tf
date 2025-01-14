resource "aws_acm_certificate" "mattermost_acm_cert" {
  domain_name       = var.domaine
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create a DNS validation record for each domain validation option
resource "aws_route53_record" "mattermost_cert_validation" {
  for_each = { for dvo in aws_acm_certificate.mattermost_acm_cert.domain_validation_options : dvo.domain_name => dvo }

  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  zone_id = var.ROUTE53_ZONE_ID # Replace with actual Route53 hosted zone ID
  records = [each.value.resource_record_value]
  ttl     = 60
}
