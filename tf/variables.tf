variable "user" {
  default = "mmussett@tibco.com"
}
variable "region" {
  description = "The AWS region to create things in."
  default     = "eu-west-1"
}

variable "profile" {
  description = "The AWS shared credential profile"
  default = "admin"
}

variable "availability_zone" {
  description = "Thae AWS Availability Zone to use"
  default = "eu-west-1a"
}

variable "shared_credential_file" {
  description ="AWS credential file"
  default = "/Users/mmussett/.aws/credentails"
}

variable vpc_cddr {
  description = "AWS VPC CDDR block"
  default = "172.17.0.0/16"
}


variable "role_arn" {
  description = "Role ARN"
  default = "arn:aws:iam::696093067220:role/TIBCO/Administrator"
}



variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  default     = "2"
}

variable "app_image" {
  description = "Docker image to run in the ECS cluster"
  default     = "091505477228.dkr.ecr.eu-west-1.amazonaws.com/tripstatus:latest"
}

variable "app_name" {
  description = "Name of the Fargate ECS Application"
  default = "tripstatus"
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 8080
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 2
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "1024"
}

