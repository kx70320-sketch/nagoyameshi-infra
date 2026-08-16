# ==============================================
# 1. 開発者（自分）のIPアドレスを定義するIPセット
# ==============================================
resource "aws_wafv2_ip_set" "developer_ip" {
  provider           = aws.us_east_1
  name               = "developer-ip-set-dev"
  description        = "IP set for my development access"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = ["27.127.148.244/32"]
}

# ==============================================
# 2. 検証用 (dev) WAF - 日本国内 ＋ 自分のIPを許可
# ==============================================
resource "aws_wafv2_web_acl" "dev" {
  provider    = aws.us_east_1
  name        = "nagoyameshi-waf-dev-2026" # 別の名前に変更
  description = "WAF for Dev CloudFront - Allow Developer IP and Japan IP"
  scope       = "CLOUDFRONT"

  default_action {
    block {}
  }

  # ルール1：自分のIPからのアクセスを許可
  rule {
    name     = "AllowDeveloperIP"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.developer_ip.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowDeveloperIPDev"
      sampled_requests_enabled   = true
    }
  }

  # ルール2：日本からのアクセスを許可
  rule {
    name     = "AllowJapanIP"
    priority = 2

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
      metric_name                = "AllowJapanIPDev"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "nagoyameshi-waf-dev"
    sampled_requests_enabled   = true
  }
}

# ==============================================
# 3. 検証用 (dev) CloudFront ディストリビューション
# ==============================================
resource "aws_cloudfront_distribution" "dev" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Nagoyameshi Dev CloudFront Distribution"
  web_acl_id          = aws_wafv2_web_acl.dev.arn

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
    Name = "nagoyameshi-cloudfront-dev"
  }
}