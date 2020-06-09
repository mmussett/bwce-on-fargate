variable access_key {
  default = ""
}

variable secret_key {
  default = ""
}

variable "shared_credential_file" {
  description ="AWS credential file"
  default = "/Users/mmussett/.aws/credentails"
}

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

variable vpc_cddr {
  description = "AWS VPC CDDR block"
  default = "172.17.0.0/16"
}

variable allowed_cidr_blocks {
  description = "Allowed ingress cddr block"
  default = "82.35.79.61/32"
}

variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  default     = "2"
}

variable "app_image" {
  description = "Docker image to run in the ECS cluster"
  default     = "696093067220.dkr.ecr.eu-west-1.amazonaws.com/tripstatus:latest"
}

variable "app_name" {
  description = "Name of the Fargate ECS Application"
  default = "tripstatus"
}

variable "app_port" {
  default = 8080
}

variable "healthcheck_port" {
  default = 7777
}


variable "app_count" {
  description = "Number of docker containers to run"
  default     = 2
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "1024"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "2048"
}


variable "cloudwatch_group" {
  description = "Logging Cloudwatch group"
  default = "tripstatus"
}