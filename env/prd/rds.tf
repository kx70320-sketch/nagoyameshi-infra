# --- DBサブネットグループ (プライベートサブネット1a, 1cに配置) ---
resource "aws_db_subnet_group" "main" {
  name       = "nagoyameshi-db-subnet-group"
  subnet_ids = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]

  tags = {
    Name = "nagoyameshi-db-subnet-group"
  }
}

# --- RDS インスタンス (MySQL) ---
resource "aws_db_instance" "main" {
  identifier        = "nagoyameshi-db"
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"

  db_name  = "nagoyameshi"
  username = "admin"
  password = var.db_password 

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # パブリックアクセスの拒否（プライベート配置）
  publicly_accessible = false

  # ★ 非機能要件: バックアップは1週間（7日間）保持
  backup_retention_period = 7

  # ★ AZ冗長化構成（コストを最優先で抑えて検証する場合は false に変更も可）
  multi_az = true

  skip_final_snapshot = true

  tags = {
    Name = "nagoyameshi-db"
  }
}