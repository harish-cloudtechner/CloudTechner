resource "aws_vpc" "main"{
  cidr_block       = var.cidr_block
  instance_tenancy = "default"
  tags = {
    Name = var.vpc_name
  }
  }
  data "aws_availability_zones" "azs"{
     state = "available"
  }
  resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.main.id
cidr_block = "${cidrsubnet(var.cidr_block,8,4)}"
  availability_zone  = "${ data.aws_availability_zones.azs.names[0]}"
  map_public_ip_on_launch = "true"
    
tags = {
    Name = var.pubsub_name1
    #Name =  "web-subnet-az-1"
  }
}
resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.main.id
cidr_block = "${cidrsubnet(var.cidr_block,8,6)}"
  availability_zone  = "${data.aws_availability_zones.azs.names[0]}"
tags = {
    Name = var.prisub_name1
    #Name =  "app-subnet-az-1"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
   # Name = "web-igw"
   Name = var.webigw_name
  }
}

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.main.id
 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
 tags = {
    #Name = "web-rt"
    Name = var.pubrt_name
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.pubrt.id
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
    cidr_blocks = "${cidrsubnet(var.cidr_block,8,6)}"
  }
  ingress {
description = "TLS from VPC"
from_port   = 80
to_port     = 80
protocol    = "tcp"
    cidr_blocks = "${cidrsubnet(var.cidr_block,8,6)}"
  }
ingress {
description = "TLS from VPC"
from_port   = -1
to_port     = -1
protocol    = "icmp"
    cidr_blocks = "${cidrsubnet(var.cidr_block,8,6)}"
 }
  egress {
    from_port   = 0 
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  tags = {
    Name = var.natsg_name
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
   ingress {
 description = "TLS from VPC"
 from_port   = -1
 to_port     = -1
 protocol    = "-1"
 security_groups = [aws_security_group.natsggroup.id]
  }

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
    cidr_blocks = "${cidrsubnet(var.cidr_block,8,4)}"
  }
  ingress {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      security_groups = [aws_security_group.natsggroup.id]
  }
  ingress {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      security_groups = [aws_security_group.pubsggroup.id]
  }
    

  egress {
    from_port   = 0 
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  tags = {
    Name = var.prisg_name
  }
}
   




#create public instances
resource "aws_instance" "publicinstance" {
  ami                    = "ami-08e0ca9924195beba"
  key_name               = "ansible"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.pubsggroup.id]
  subnet_id              = aws_subnet.main1.id
  tags= {
    Name = var.publicinst_name
  }
}

#create private instance
resource "aws_instance" "privateinstance" {
  ami                    = "ami-08e0ca9924195beba"
  key_name               = "singh"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.prisggroup.id]
  subnet_id              = aws_subnet.main2.id
  tags= {
    Name = var.privateins_name
  }
}
#create nat instance
resource "aws_instance" "natinstance" {
  ami                    = "ami-00999044593c895de"
  key_name               = "singh"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.natsggroup.id]
  subnet_id              = aws_subnet.main1.id
  source_dest_check      = "false"
  tags= {
    Name = var.natinst_name
  }
}
resource "aws_route_table" "r1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = aws_instance.natinstance.id
  }
 tags = {
    Name = var.privateroutetable_name
  }
}
resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.main2.id
  route_table_id = aws_route_table.r1.id
}
# resource "aws_security_group" "mydb1" {
#   name = "mydb1sg"

#   description = "RDS postgres servers (terraform-managed)"
#   vpc_id = aws_vpc.main.id

#   # Only postgres in
#   ingress {
#     from_port = 3306
#     to_port = 3306
#     protocol = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # Allow all outbound traffic.
#   egress {
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
# resource "aws_db_subnet_group" "dbgroup" {
#   name       = "dbsubgroup"
#   subnet_ids = [aws_subnet.main1.id, aws_subnet.main2.id, aws_subnet.main3.id]

#   tags = {
#     Name = "My DB subnet group"
#   }
# }
# resource "aws_db_instance" "dbinst" {
#   allocated_storage    = 20
#   storage_type         = "gp2"
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t2.micro"
#   name                 = "mydb"
#   username             = "harish"
#   password             = "harish2707"
#   db_subnet_group_name = aws_db_subnet_group.dbgroup.id
#   final_snapshot_identifier = "final-snapshot"
#   skip_final_snapshot = true
# }
# resource "aws_s3_bucket" "b" {
#   bucket = "terraformbuckhari"
#   acl    = "private"

#   tags = {
#     Name        = "cloud_bucket"
#     Environment = "default"
#   }
# }
#terraform {
#  backend "s3" {
#    # Replace this with your bucket name!
#    bucket         = "terabuck"
#    key            = "global/s3/terraform.tfstate"
#    region         = "ap-south-1"
#    encrypt        = true
#  }
#  }

