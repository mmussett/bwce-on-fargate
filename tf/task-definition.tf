resource "aws_ecs_task_definition" "app" {
  depends_on = [aws_alb_listener.front_end]
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  task_role_arn            = aws_iam_role.task-role.arn
  execution_role_arn       = aws_iam_role.execution-role.arn
  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${var.app_image}",
    "memory": ${var.fargate_memory},
    "memoryReservation": ${var.fargate_memory},
    "essential": true,
    "name": "${var.app_name}",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      },
      {
        "containerPort": 7777,
        "hostPort": 7777
      }
    ],
    "environment": [
      {
        "name": "BW_LOGLEVEL",
        "value": "INFO"
      }
    ],
    "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "${var.cloudwatch_group}",
            "awslogs-region": "eu-west-1",
            "awslogs-stream-prefix": "ecs"
          }
        }
  }
]
DEFINITION
}