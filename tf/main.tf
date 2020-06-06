/*
provider "aws" {
  region = var.region
  shared_credentials_file = var.shared_credential_file
  profile = var.profile
}
*/

provider "aws" {
    region = var.region
    access_key = "AKIARKTRGYZWHJJV6GVQ"
    secret_key = "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"
}

### IAM

# Create IAM policy
resource "aws_iam_policy" "access_policy" {
  name = "mm-bwce-fargate-AmazonECSTaskExecutionRolePolicy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_iam_role" "role" {
  name = "mm-bwce-fargate-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "ecs-tasks.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
    role       = aws_iam_role.role.name
    policy_arn = aws_iam_policy.access_policy.arn
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ECSTaskExecutionRole"
}

### Network

# Fetch AZs in the current region
data "aws_availability_zones" "available" {}


resource "aws_vpc" "main" {
  cidr_block = var.vpc_cddr

  tags = {
      Name = "mm-bwce-fargate-vpc"
      User = var.user
  }
}

# Create var.az_count private subnets, each in a different AZ
resource "aws_subnet" "private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id

    tags = {
      Name = "mm-bwce-fargate-private-sn"
      User = var.user
  }

}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

    tags = {
      Name = "mm-bwce-fargate-public-sn"
      User = var.user
  }
}


# IGW for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

    tags = {
      Name = "mm-bwce-fargate-igw"
      User = var.user
  }

}


# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}


# Create a NAT gateway with an EIP for each private subnet to get internet connectivity
resource "aws_eip" "gw" {
  count      = var.az_count
  vpc        = true
  depends_on = [aws_internet_gateway.gw]
}



resource "aws_nat_gateway" "gw" {
  count         = var.az_count
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)

      tags = {
      Name = "mm-bwce-fargate-ngw"
      User = var.user
  }

}


# Create a new route table for the private subnets
# And make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
  }

tags = {
      Name = "mm-bwce-fargate-ngw"
      User = var.user
  }
}

# Explicitely associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}




### Security

# ALB Security group
# This is the group you need to edit if you want to restrict access to your application
resource "aws_security_group" "lb" {
  name        = "mm-bwce-fargate-alb"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
      Name = "mm-bwce-fargate-alb-sg"
      User = var.user
  }

}


# Traffic to the ECS Cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "mm-bwce-fargate-alb-tasks"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags = {
      Name = "mm-bwce-fargate-alb-sg"
      User = var.user
  }
} 




### ALB


resource "aws_alb" "main" {
  name            = "mm-bwce-fargate"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.lb.id]
  subnets         = aws_subnet.public.*.id

      tags = {
      Name = "mm-bwce-fargate-alb"
      User = var.user
  }
}

resource "aws_alb_target_group" "app" {
  name        = "mm-bwce-fargate"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

      tags = {
      Name = "mm-bwce-fargate-alb-tg"
      User = var.user
  }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }
}


### ECS

resource "aws_ecs_cluster" "main" {
  name = "mm-bwce-fargate-ecs-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  task_role_arn            = aws_iam_role.role.arn
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${var.app_image}",
    "memory": ${var.fargate_memory},
    "name": "${var.app_name}",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.app_port},
        "hostPort": ${var.app_port}
      }
    ]
  }
]
DEFINITION
}


resource "aws_ecs_service" "main" {
  name            = "tf-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = var.app_name
    container_port   = var.app_port
  }

  depends_on = [
    aws_alb_listener.front_end,
  ]
}
 