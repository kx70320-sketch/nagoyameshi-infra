# ALB本体
resource "aws_lb" "main" {
  name               = "nagoyameshi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]

  tags = {
    Name = "nagoyameshi-alb"
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "main" {
  name        = "nagoyameshi-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health" # 補足資料の指定「/health」
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "nagoyameshi-tg"
  }
}

# HTTPリスナー（HTTPSへの強制的リダイレクト）
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPSリスナー（追加分：ACM証明書を紐づけてターゲットグループへ転送）
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn # variables.tf等で定義、または手動作成した証明書のARNを指定

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}