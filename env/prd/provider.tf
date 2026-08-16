terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Nagoyameshi"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}
# CloudFront用WAF作成のための us-east-1 プロバイダー設定
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "Nagoyameshi"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}