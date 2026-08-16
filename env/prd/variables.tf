variable "aws_region" {
  type        = string
  default     = "ap-northeast-1"
  description = "AWS Region"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR Block"
}

# --- ALB HTTPS化用のACM証明書ARN（手動作成後に渡す場合など） ---
variable "acm_certificate_arn" {
  type        = string
  default     = ""
  description = "ACM Certificate ARN for ALB HTTPS Listener"
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}