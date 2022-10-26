resource "aws_ecs_cluster" "internal" {
  name = "internal"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "internal" {
  name                   = "internal"
  cluster                = aws_ecs_cluster.internal.id
  task_definition        = aws_ecs_task_definition.internal.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    security_groups = [aws_security_group.internal.id]
    subnets         = module.vpc.private_subnet_ids
  }
}

resource "aws_ecs_task_definition" "internal" {
  family                   = "internal"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 256
  memory = 512

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "httpd",
      "cpu" : 0,
      "environment" : [],
      "essential" : true,
      "image" : "${aws_ecr_repository.internal.repository_url}:latest",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.internal.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-internal"
        }
      },
      "portMappings" : [
        {
          "hostPort" : 80,
          "ContainerPort" : 80,
          "Protocol" : "tcp"
        }
      ],
      "secrets" : [],
    }
  ])
}

resource "aws_cloudwatch_log_group" "internal" {
  name              = "/aws/ecs/internal"
  retention_in_days = 14
}
