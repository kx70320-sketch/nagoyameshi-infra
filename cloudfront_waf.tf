# ==============================================
# 1. 開発者（自分）のIPアドレスを定義するIPセット（dev用WAFで使用）
# ==============================================
resource "aws_wafv2_ip_set" "developer_ip" {
  provider           = aws.us_east_1
  name               = "developer-ip-set"
  description        = "IP set for my development access"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = ["27.127.148.244/32"]
}

# ==============================================
# 2. 本番用 (prd) WAF - 日本国内のアクセスのみ許可
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
# 3. 検証用 (dev) WAF - 日本国内 ＋ 自分のIPを許可
# ==============================================
resource "aws_wafv2_web_acl" "dev" {
  provider    = aws.us_east_1
  name        = "nagoyameshi-waf-dev"
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
# 4. 本番用 (prd) CloudFront ディストリビューション
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

# ==============================================
# 5. 検証用 (dev) CloudFront ディストリビューション
# ※必要であれば別ドメインやサブドメインを設定できますが、
#   まずは同じ構成でWAFの挙動（dev用）を独立させます
# ==============================================
resource "aws_cloudfront_distribution" "dev" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Nagoyameshi Dev CloudFront Distribution"
  web_acl_id          = aws_wafv2_web_acl.dev.arn

  # ※もし検証用サブドメインがあれば aliases に追加できますが、
  #   まずはデフォルトの CloudFront ドメイン (*.cloudfront.net) でアクセス確認可能です

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