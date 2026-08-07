# ---------------------------------------------
# ALB用セキュリティグループ
# ---------------------------------------------
resource "aws_security_group" "alb" {
  name        = "nagoyameshi-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  # HTTP (HTTPSへのリダイレクト用)
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nagoyameshi-alb-sg"
  }
}

# ---------------------------------------------
# ECS用セキュリティグループ (ALBからのアクセスのみ許可)
# ---------------------------------------------
resource "aws_security_group" "ecs" {
  name        = "nagoyameshi-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nagoyameshi-ecs-sg"
  }
}

# ---------------------------------------------
# RDS用セキュリティグループ (ECSからのアクセスのみ許可)
# ---------------------------------------------
resource "aws_security_group" "db" {
  name        = "nagoyameshi-db-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow MySQL from ECS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nagoyameshi-db-sg"
  }
}