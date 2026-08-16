# ==============================================
# 1. 本番用 (prd) WAF - 日本国内のアクセスのみ許可
# ==============================================
resource "aws_wafv2_web_acl" "prd" {
  provider    = aws.us_east_1
  name        = "nagoyameshi-waf-prd"
  description = "WAF for Prd CloudFront - Allow Japan IP only"
  scope       = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    name     = "AllowJapanIP"
    priority = 1

    action {
      allow {}
    }

    statement {
      geo_match_statement {
        country_codes = ["JP"]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowJapanIPPrd"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "nagoyameshi-waf-prd"
    sampled_requests_enabled   = true
  }
}

# ==============================================
# 2. 本番用 (prd) CloudFront ディストリビューション
# ==============================================
resource "aws_cloudfront_distribution" "prd" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Nagoyameshi Prd CloudFront Distribution"
  web_acl_id          = aws_wafv2_web_acl.prd.arn

  aliases = ["nagoyameshi-fuchisaki.click"]

  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = aws_lb.main.name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_lb.main.name

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:988745870829:certificate/d0aa18af-cc48-4508-8976-3e2e2ca7302a"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "nagoyameshi-cloudfront-prd"
  }
}