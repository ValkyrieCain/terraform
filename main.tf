terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.31.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "container_vpc"
  }
}

#main subnet 1
resource "aws_subnet" "host_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "subnet_1"
  }
  depends_on = [aws_vpc.main]
}
#main subnet 2
resource "aws_subnet" "host_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "subnet_2"
  }
  depends_on = [aws_vpc.main]
}
#main instance 1
resource "aws_instance" "host_1" {
  ami           = "ami-00f9f4069d04c0c6e"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.host_1.id
  user_data     = file("user_data.sh")
  tags = {
  Name = "worker_1" }
  root_block_device {
    volume_size = "10"
  }
  depends_on = [aws_subnet.host_1]
}
#main instance 2
resource "aws_instance" "host_2" {
  ami           = "ami-00f9f4069d04c0c6e"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.host_2.id
  user_data     = file("user_data.sh")
  tags = {
  Name = "worker_2" }
  root_block_device {
    volume_size = "10"
  }
  depends_on = [aws_subnet.host_2]
}
#autoscaling up
resource "aws_autoscaling_policy" "up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 30
  autoscaling_group_name = aws_autoscaling_group.run.name
  depends_on             = [aws_instance.host_1, aws_instance.host_2, aws_launch_configuration.set]
}
#scale up trigger
resource "aws_cloudwatch_metric_alarm" "memory-high" {
  alarm_name          = "high-memory"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_actions = [
    aws_autoscaling_policy.up.arn
  ]

}

#autoscaling down
resource "aws_autoscaling_policy" "down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 30
  autoscaling_group_name = aws_autoscaling_group.run.name
  depends_on             = [aws_instance.host_1, aws_instance.host_2, aws_launch_configuration.set]
}

#scale down trigger
resource "aws_cloudwatch_metric_alarm" "memory-low" {
  alarm_name          = "low-memory"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  alarm_actions = [
    aws_autoscaling_policy.down.arn
  ]

}

#autoscaling group
resource "aws_autoscaling_group" "run" {
  availability_zones        = ["us-west-2a", "us-west-2b", "us-west-2c"]
  name                      = "scaling"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 30
  health_check_type         = "ELB"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.set.name
}
#launching autoscaling
resource "aws_launch_configuration" "set" {
  name          = "scale_config"
  image_id      = "ami-0272e7da2bc6b98d1"
  instance_type = "t2.micro"
  depends_on    = [aws_instance.autoscaling]
}
#autoscaling subnet
resource "aws_subnet" "autoscaling" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "autoscaling"
  }
  depends_on = [aws_vpc.main]
}
#autoscaling instance
resource "aws_instance" "autoscaling" {
  ami           = "ami-00f9f4069d04c0c6e"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.autoscaling.id

  tags = {
  Name = "autoscaling" }
  root_block_device {
    volume_size = "10"
  }
  depends_on = [aws_subnet.autoscaling]

}
