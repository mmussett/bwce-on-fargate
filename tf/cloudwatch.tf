
### Cloudwatch

resource "aws_cloudwatch_log_group" "cw" {
  name = var.cloudwatch_group

  tags = {
      Name = "mm-bwce-fargate-cwg"
      User = var.user
  }
}
