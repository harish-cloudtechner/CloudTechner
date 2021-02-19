resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
}
resource "aws_subnet" "main1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.pubcidr_block

  tags = {
    Name = var.pubsubnet_name
  }
}
resource "aws_subnet" "main2" {
  vpc_id     = aws_vpc.main.id
cidr_block = var.pricidr_block

tags = {
    Name = var.prisubnet_name
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.igw_name
  }
}
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.routecidr_block
    gateway_id = aws_internet_gateway.gw.id
  }
 tags = {
    Name = var.routetable_name
  }
}


#public security group
resource "aws_security_group" "pubsggroup" {
  name        = var.pubsg_name
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
description = "TLS from VPC"
from_port   = 80
to_port     = 80
protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
description = "TLS from VPC"
from_port   = 22
to_port     = 22
protocol    = "tcp"
    cidr_blocks = ["13.233.177.0/29"] 
 }
  ingress {
description = "TLS from VPC"
from_port   = 8080
to_port     = 8080
protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
 }
  
#   ingress {
#description = "TLS from VPC"
#from_port   = -1
#to_port     = -1
#protocol    = "-1"
#    cidr_blocks = [aws_security_group.natsggroup.id] 
# }
egress {
    from_port   = 0 
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
    
  tags = {
    Name = var.pubsg_name
  }
}


#private security group
resource "aws_security_group" "prisggroup" {
  name        = var.prisg_name
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    from_port   = 0 
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
#ingress {
#escription = "TLS from VPC"
#from_port   = 8080
#to_port     = 8080
#protocol    = "tcp"
 #   cidr_blocks = [aws_security_group.pubsggroup.id]
  #}
#ingress {
#description = "TLS from VPC"
#from_port   = -1
#to_port     = -1
#protocol    = "-1"
#    cidr_blocks = [aws_security_group.natsggroup.id] 
 #}
tags = {
    Name = var.prisg_name
  }
}


#nat security group
resource "aws_security_group" "natsggroup" {
  name        = var.natsg_name
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
description = "TLS from VPC"
from_port   = 443
to_port     = 443
protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }
  ingress {
description = "TLS from VPC"
from_port   = 80
to_port     = 80
protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }
ingress {
description = "TLS from VPC"
from_port   = -1
to_port     = -1
protocol    = "icmp"
    cidr_blocks = ["10.0.2.0/24"] 
 }
  egress {
    from_port   = 0 
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
# ingress {
#description = "TLS from VPC"
#from_port   = -1
#to_port     = -1
#protocol    = "-1"
#    cidr_blocks = [aws_security_group.prisggroup.id] 
 #}
tags = {
    Name = var.prisg_name
  }
}
#resource "aws_security_group_rule" "pubsggroup" {
 # type              = "ingress"
  #from_port         = -1
  #to_port           = -1
  #protocol          = "-1"
  #cidr_blocks       = [aws_security_group.natsggroup.id]
  #security_group_id = aws_security_group.pubsggroup.id
#}
