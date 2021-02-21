import os

project=str(input("Enter project name: "))

cidr=str(input("Enter cidr block for vpc: "))

scidr=str(input("enter cidr block for public subnet: "))

pcidr=str(input("Enter cidr block for private subnet: "))

rcidr=str(input("Enter cidr block for rds subnet: "))
 
terraformtfvars="""region = "ap-south-1"
environment_name = "dev"
project_name = "abc"
cidr_block = "x"
vpc_name = "yogesh-vpc"
sub_cidr = "y"
sub_name = "yogesh-pubsub"
pvt_cidr = "10.0.0.0/24"
pvt_name = "yogesh-pvtsub"
subrds_cidr = "z"
subrds_name = "yogesh-rdssub"
igw_name = "yogesh-igw"
pub_route = "yogesh-pubroute"
natsg_name = "yogesh-natsgroup"
pubsg_name = "yogesh-pubsgroup"
pvtsg_name = "yogesh-pvtsgroup"
natinsname = "yogesh-natins"
newpub = "yogesh-pubins"
newpvt = "yogesh-pvtins"
pvtroute = "yogesh-pvtroute" """
terraformtfvars =terraformtfvars.replace("x",cidr)
terraformtfvars = terraformtfvars.replace("y",scidr)
terraformtfvars = terraformtfvars.replace("10.0.0.0/24",pcidr)
terraformtfvars = terraformtfvars.replace("10.0.3.0/24",rcidr)
terraformtfvars = terraformtfvars.replace("yogesh",project)
file = open("terraform.tfvars", "w") 
file.write(terraformtfvars) 
file.close()

variables="""variable "region" {}
variable "environment_name" {}
variable "project_name" {}
variable "cidr_block" {}
variable "vpc_name" {}
variable "sub_cidr" {}
variable "sub_name" {}
variable "pvt_cidr" {}
variable "pvt_name" {}
variable "subrds_cidr" {}
variable "subrds_name" {}
variable "igw_name" {}
variable "pub_route" {}
variable "natsg_name" {}
variable "pubsg_name" {}
variable "pvtsg_name" {}
variable "natinsname" {}
variable "newpub" {}
variable "newpvt" {}
variable "pvtroute" {} """
file = open("variables.tf", "w") 
file.write(variables) 
file.close()

assignment="""resource "aws_vpc" "default" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"
   
  tags = {
    Name = var.vpc_name
  }
}
output "vpc_id" {
  description = "The id of vpc"
  value       = aws_vpc.default.id
}
resource "aws_subnet" "main" { 
  vpc_id     = aws_vpc.default.id
  cidr_block = var.sub_cidr
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1a"
  tags = {
    Name = var.sub_name
   }
}
output "sub_id" {
  description = "id of public subnet"
  value       = aws_subnet.main.id
}                                  
resource "aws_subnet" "pvt" {
  vpc_id     = aws_vpc.default.id
  cidr_block = var.pvt_cidr
  availability_zone = "ap-south-1a"
  tags = {
    Name = var.pvt_name
   }
}
output "pvt_id" {
  description = "Id of private subnet"
  value       = aws_subnet.pvt.id
}
resource "aws_subnet" "rds" {
  vpc_id     = aws_vpc.default.id
  cidr_block = var.subrds_cidr
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1b"
  tags = {
    Name = var.subrds_name
   }
}
output "subrds_id" {
  description = "Id of rds private subnet"
  value       = aws_subnet.rds.id
}
resource "aws_db_subnet_group" "subnet_group" {
  name        = "my_subnet_group"
  subnet_ids  = [aws_subnet.pvt.id,aws_subnet.main.id,aws_subnet.rds.id]
  description = "subnet group for rds"
  tags = {
    Name = "subnetgroup"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id     = aws_vpc.default.id
                                                                              
  tags = {
    Name = var.igw_name
   }
}
output "igw_id" {
  description = "Id of igw"
  value       = aws_internet_gateway.gw.id
}
resource "aws_route_table" "pub_route" {
  vpc_id = aws_vpc.default.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
   }
 
  tags = {
    Name = var.pub_route
   }
}
output "pub_rid" {
  description = "Id of public route table"
  value       = aws_route_table.pub_route.id
}
resource "aws_route_table_association" "associate" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.pub_route.id
}
resource "aws_security_group" "nat_sg" {
  name = "nat_sg"
  vpc_id = aws_vpc.default.id
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [var.pvt_cidr]
  }
  ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.pvt_cidr]
  }
  ingress {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = [var.pvt_cidr]
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
resource "aws_security_group" "pub_sg" {
  name = "public_sg"
  vpc_id = aws_vpc.default.id
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "icmp"
      cidr_blocks = ["13.233.117.0/29"]
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
resource "aws_security_group" "pvt_sg" {
  name = "private_sg"
  vpc_id = aws_vpc.default.id
  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.sub_cidr]
  }
  ingress {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      security_groups = [aws_security_group.nat_sg.id]
  }
  ingress {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      security_groups = [aws_security_group.pub_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.pvtsg_name
  }
}  
resource "tls_private_key" "example" {
  algorithm = "RSA" 
  rsa_bits = 4096
}
resource "aws_key_pair" "generated_key" { 
  key_name = "my_key" 
  public_key = "${tls_private_key.example.public_key_openssh}"
}
resource "aws_instance" "natins" {
  ami           = "ami-00999044593c895de"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id
  security_groups = [aws_security_group.nat_sg.id]
  source_dest_check = "false"
  tags = {
    Name = var.natinsname
   }
}
output "nat_id" {
  description       = "nat id instance"
  value             = aws_instance.natins.id
}
resource "aws_instance" "pub_ins" {
  ami           = "ami-08e0ca9924195beba"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id
  security_groups = [aws_security_group.pub_sg.id]
  tags = {
    Name = var.newpub
   }
}
output "pub_id" {
  description = "public id"
  value       = aws_instance.pub_ins.id
}
resource "aws_instance" "pvt_ins" {
  ami           = "ami-08e0ca9924195beba"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.pvt.id
  security_groups = [aws_security_group.pvt_sg.id]
 
  tags = {
    Name = var.newpvt
   }
}
output "pvtins_id" {
  description = "private id"
  value       = aws_instance.pvt_ins.id
}
resource "aws_route_table" "pvt_route" {
  vpc_id = aws_vpc.default.id
  
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = aws_instance.natins.id
   }
 
  tags = {
    Name = var.pvtroute
   }
}
output "pvt_rid" {
  description = "Id of private route table"
  value       = aws_route_table.pvt_route.id
}
resource "aws_route_table_association" "associate2" {
  subnet_id      = aws_subnet.pvt.id
  route_table_id = aws_route_table.pvt_route.id
}
resource "aws_db_instance" "defult" {
  allocated_storage = 20
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  name = "teraform"
  username = "yogesh"
  password = "helloyogesh"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name =aws_db_subnet_group.subnet_group.name
  final_snapshot_identifier = "final-snapshot"
  skip_final_snapshot = true
}
resource "aws_s3_bucket" "buck1" {
  bucket = "pynano5python"
  acl    = "private"   
  tags = {
    Name        = "teraformbucket"
  }
}
terraform {
  backend "s3" {
    bucket         = "pynano5python"
    key            = "global/s3/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
  }
}"""
file = open("vpc.tf", "w") 
file.write(assignment) 
file.close()


provider="""provider "aws" {
    region = var.region
    shared_credentials_file = "${var.project_name}.credentials"
    profile = var.environment_name
}"""
file = open("provider.tf", "w") 
file.write(provider) 
file.close()

project_credentials="""[dev]
AWSAccessKeyId=AKIAJEPV7O4SJR5G6NKQ
AWSSecretKey=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"""
file = open("project.credentials", "w") 
file.write(project_credentials) 
file.close()

os.system('terraform init')
os.system('terraform validate')
os.system('terraform plan')
os.system('terraform apply')
