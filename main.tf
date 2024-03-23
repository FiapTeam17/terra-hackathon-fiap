terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
  required_version = ">= 1.1.0"

  # cloud {
  #   organization = "sgr-fiap-17"

  #   workspaces {
  #     name = ""
  #   }
  # }
}

provider "aws" {
  region     = "us-east-2" # Substitua pela sua região AWS desejada
  access_key = "x"
  secret_key = "x+b9/K3KLu"
}

locals {
  name   = "hackaton-vpc"
  region = "us-east-2"

  vpc_cidr = "10.123.0.0/16"
  azs      = ["us-east-2a", "us-east-2b"]

  subnets = ["subnet-00357059bc16ff3dc", "subnet-042f09e24438af85a", "subnet-0c7d8db7ca3beca5d"]

  public_subnets  = ["10.123.1.0/24", "10.123.2.0/24"]
  private_subnets = ["10.123.3.0/24", "10.123.4.0/24"]
  intra_subnets   = ["10.123.5.0/24", "10.123.6.0/24"]

  tags = {
    Example = local.name
  }
}

# ================================= ECS =================================

resource "aws_ecs_cluster" "hackaton-cluster" {
  name = "hackaton-gerencial-cluster"
}

# ================================= TASK DEFINITIONS =================================

resource "aws_ecs_task_definition" "hackaton-task-gerencial" {

  family                   = "hackaton-gerencial"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  cpu                      = 256
  memory                   = 2048
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([{
    name  = "hackaton-gerencial-task"
    image = "190197150713.dkr.ecr.us-east-2.amazonaws.com/hackaton-fiap"
    environment : [
      {
        "name" : "DB_USER",
        "value" : "cm9vdA=="
      },
      {
        "name" : "DB_SERVER",
        "value" : "ZmlhcC1oYWNrYXRvbi5jdTd5ajNnamprczEudXMtZWFzdC0yLnJkcy5hbWF6b25hd3MuY29t"
      },
      {
        "name" : "DB_SCHEMA",
        "value" : "Y29udHJvbGVfcG9udG8="
      },
      {
        "name" : "DB_PASS",
        "value" : "c2VuaGExMjM="
      },
      {
        "name" : "AWS_ACCESS_KEY_ID",
        "value" : "x"
      },
      {
        "name" : "AWS_SECRET_ACCESS_KEY",
        "value" : "x"
      },
      {
        "name" : "REGION",
        "value" : "dXMtZWFzdC0y"
      },

      {
        "name" : "AWS_REGION",
        "value" : "us-east-2"
      },
      {
        "name" : "CLIENT_LOGIN_ID",
        "value" : "MjNxbnRiMmhtMGlrNjI3YTQ4aDRsdjljdDk="
      },
      {
        "name" : "CLIENT_ID",
        "value" : "Y2dmYnQ5MWN1azZhZ3Y1ZTA3cms0ZmZpNA=="
      },
      {
        "name" : "AWS_CLIENT_ID",
        "value" : "QUtJQVNZU0ZDR1A0NEcyNVVFVlg="
      },
      {
        "name" : "AWS_CLIENT_SECRET",
        "value" : "ZUJncWlrejRyZGxuMVZ0V3o1SnZESEVWM0drRlRmQStiOS9LM0tMdQ=="
      },
    ],
  }])
}


# ================================= SERVICES =================================

resource "aws_ecs_service" "ecs-service-hackaton-gerencial" {
  name            = "hackaton-gerencial-service-ecs"
  cluster         = aws_ecs_cluster.hackaton-cluster.id
  task_definition = aws_ecs_task_definition.hackaton-task-gerencial.arn
  launch_type     = "FARGATE"
  network_configuration {
    assign_public_ip = true
    security_groups  = ["sg-00d1f939e5014dc5b"]
    subnets          = local.subnets
  }
  desired_count = 1
  depends_on    = [aws_ecs_task_definition.hackaton-task-gerencial]
}

# ================================= IAM ROLES =================================

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

variable "iam_policy_name" {
  type    = string
  default = "ecs-iam-policy"
}

resource "aws_iam_policy" "ecs-iam-policy" {
  name = var.iam_policy_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role

resource "aws_iam_policy_attachment" "ecs_iam_iam_policy_attachment" {
  name       = "Policy Attachement"
  policy_arn = aws_iam_policy.ecs-iam-policy.arn
  roles      = [aws_iam_role.ecs_execution_role.name]
}
