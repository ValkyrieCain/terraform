#elb
resource "aws_elb" "web" {
  name            = "web-elb"
  subnets         = aws_subnet.public_subnet[*].id
  security_groups = aws_security_group.elb_sg[*].id
  instances       = [aws_instance.host_1.id, aws_instance.host_2.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}


#elb security group
resource "aws_security_group" "elb_sg" {
  name        = "ELB SG"
  description = "Allow incoming HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
