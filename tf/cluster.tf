resource "aws_ecs_cluster" "main" {
  name = "mm-bwce-fargate-ecs-cluster"

  tags = {
      Name = "mm-bwce-fargate-cluster"
      User = var.user
  }
}