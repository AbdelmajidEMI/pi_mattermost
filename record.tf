resource "aws_route53_record" "mattermost_a_record" {
  zone_id = var.ROUTE53_ZONE_ID     
  name    = var.domaine         
  type    = "A"

  alias {
    name                   = aws_lb.mattermost_alb.dns_name
    zone_id                = aws_lb.mattermost_alb.zone_id
    evaluate_target_health = false
  }
}

