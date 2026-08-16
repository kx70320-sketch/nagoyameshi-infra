# --- ECR リポジトリ (Docker画像を保存する場所) ---
resource "aws_ecr_repository" "app" {
  name                 = "nagoyameshi-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "nagoyameshi-ecr"
  }
}

# --- ECS クラスタ ---
resource "aws_ecs_cluster" "main" {
  name = "nagoyameshi-cluster"

  tags = {
    Name = "nagoyameshi-cluster"
  }
}

# --- ECS タスク実行ロール (AWSリソースにアクセスするための権限) ---
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "nagoyameshi-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- ECS タスクロール (ECS Exec等で使う権限) ---
resource "aws_iam_role" "ecs_task_role" {
  name = "nagoyameshi-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# ★ 先生指示: ECS Exec (SSM経由のコマンド実行) を許可するためのインラインポリシー追加
resource "aws_iam_role_policy" "ecs_exec_policy" {
  name = "nagoyameshi-ecs-exec-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- CloudWatch ロググループ (ログ出力用) ---
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/nagoyameshi"
  retention_in_days = 7
}

# --- ECS タスク定義 ---
resource "aws_ecs_task_definition" "app" {
  family                   = "nagoyameshi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "nagoyameshi-app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/nagoyameshi"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# --- ECS サービス ---
resource "aws_ecs_service" "main" {
  name            = "nagoyameshi-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # ★ 先生指定: ECS Exec を有効化
  enable_execute_command = true

  network_configuration {
    subnets          = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "nagoyameshi-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}