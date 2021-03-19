#internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
#route table for internet gateway
resource "aws_route_table" "internet" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  #tags {
  #  Name = "Internet Facing"
  #}
}
#internet facing subnets
resource "aws_subnet" "public_subnet" {

  count      = 2
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.network_cidr, 2, count.index + 1)
  # [10.0.12.0/24, 10.0.24.0/24]
  # cidrsubnet(var.network_cidr, 2, count.index + 2)

  availability_zone = element(var.availability_zones, count.index)
  #  tags {
  #    Name = "Public Subnet ${count.index + 1}"
  #  }
}


resource "aws_route_table_association" "public_subnet_rta" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
  route_table_id = aws_route_table.internet.id
}
#security group for internet access
resource "aws_security_group" "web_sg" {
  name        = "Internet Access"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id


  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.elb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
