# ---------------------------------------------
# WAF (Web ACL - 日本国内IPのみ許可)
# ※CloudFront用WAFは us-east-1 で作成する必要があります
# ---------------------------------------------
resource "aws_wafv2_web_acl" "main" {
  provider    = aws.us_east_1
  name        = "nagoyameshi-waf"
  description = "WAF for CloudFront - Allow Japan IP only"
  scope       = "CLOUDFRONT"

  default_action {
    block {} # 基本はブロック
  }

  # 日本からのアクセスを許可するルール
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
      metric_name                = "AllowJapanIP"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "nagoyameshi-waf"
    sampled_requests_enabled   = true
  }
}

# ---------------------------------------------
# CloudFront ディストリビューション
# ---------------------------------------------
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Nagoyameshi CloudFront Distribution"
  web_acl_id          = aws_wafv2_web_acl.main.arn

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
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "nagoyameshi-cloudfront"
  }
}