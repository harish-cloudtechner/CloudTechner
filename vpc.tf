import os

project=str(input("Enter project name: "))

cidr=str(input("Enter cidr block for vpc: "))

scidr=str(input("enter cidr block for public subnet: "))

pcidr=str(input("Enter cidr block for private subnet: "))

rcidr=str(input("Enter cidr block for rds subnet: "))

terraformtfvars="""region = "ap-south-1"
environment_name = "default"
project_name = "credential"
vpc_name = "demo-vpc"
cidr_block = "x"
pubsubnet_name = "demo-pubsub"
pubcidr_block = "y"
prisubnet_name = "demo-prisub"
pricidr_block = "z"
igw_name = "demo-igw"
routetable_name = "demo-pubrt"
#routecidr_block = "0.0.0.0/0"
pubsg_name = "demo-pubsg1"
prisg_name = "demo-prisg1"
natsg_name = "demo-natsg1"
dbsub_name = "demo-dbsubnet"
publicinst_name = "demo-pubint"
privateins_name = "demo-priinst"
natinst_name    = "demo-natinst"
privateroutetable_name = "demo-prirt" """
terraformtfvars = terraformtfvars.replace("demo",project)
terraformtfvars =terraformtfvars.replace("x",cidr)
terraformtfvars = terraformtfvars.replace("y",scidr)
terraformtfvars = terraformtfvars.replace("z",pcidr)
#terraformtfvars = terraformtfvars.replace("10.0.3.0/24",rcidr)
file = open("terraform.tfvars", "w") 
file.write(terraformtfvars) 
file.close()

variables="""variable "region" {}
variable "environment_name" {}
variable "project_name" {}
variable "cidr_block" {}
variable "vpc_name" {}
variable "pubcidr_block" {}
variable "pubsubnet_name" {}
variable "pricidr_block" {}
variable "prisubnet_name" {}
variable "igw_name" {}
variable "routecidr_block" {}
variable "routetable_name" {}
variable "pubsg_name" {}
variable "prisg_name" {}
variable "natsg_name" {}
variable "dbsub_name" {}
variable "publicinst_name" {}
variable "privateins_name" {}
variable "natinst_name" {}
variable "privateroutetable_name" {}"""
file = open("variables.tf", "w") 
file.write(variables) 
file.close()

project_credentials="""[default]
aws_access_key_id = AKIAJLHEZ34MNBHGEVBA
aws_secret_access_key = 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"""
file = open("project.credentials", "w") 
file.write(project_credentials) 
file.close()

provider="""provider "aws" {
shared_credentials_file = "${var.project_name}.credential"
region  = var.region
profile = var.environment_name
}"""
file = open("provider.tf", "w") 
file.write(provider) 
file.close()


assignment="""resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
}


resource "aws_subnet" "main1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.pubcidr_block
  availability_zone  = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = var.pubsubnet_name
  }
}


resource "aws_subnet" "main2" {
  vpc_id     = aws_vpc.main.id
cidr_block = var.pricidr_block
  availability_zone  = "ap-south-1a"

tags = {
    Name = var.prisubnet_name
  }
}

resource "aws_subnet" "main3" {
  vpc_id     = aws_vpc.main.id
 cidr_block = "10.0.3.0/24"
  availability_zone  = "ap-south-1b"

tags = {
    Name = var.dbsub_name
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
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main1.id
  route_table_id = aws_route_table.r.id
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
#    ingress {
#  description = "TLS from VPC"
#  from_port   = -1
#  to_port     = -1
#  protocol    = "-1"
#  security_groups = aws_security_group.natsggroup.id
#   }

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
    
#   ingress {
# description = "TLS from VPC"
# from_port   = -1
# to_port     = -1
# protocol    = "-1"
# security_groups = aws_security_group.natsggroup.id
#  }
  
#    ingress {
# description = "TLS from VPC"
# from_port   = 8080
# to_port     = 8080
# protocol    = "tcp"
# security_groups = aws_security_group.pubsggroup.id
#  }
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
   
# # natsg ingress rule 
#   natsggroup_ingress {
# description = "TLS from VPC"
# from_port   = -1
# to_port     = -1
# protocol    = "-1"
# security_groups = prisggroup 
#  }

# tags = {
#     Name = var.prisg_name
#   }
# }



#create public instances
resource "aws_instance" "publicinstance" {
  ami                    = "ami-08e0ca9924195beba"
  key_name               = "harish"
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
  key_name               = "harish"
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
  key_name               = "harish"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.natsggroup.id]
  subnet_id              = aws_subnet.main1.id
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
resource "aws_db_subnet_group" "dbgroup" {
  name       = "dbsubgroup"
  subnet_ids = [aws_subnet.main1.id, aws_subnet.main2.id, aws_subnet.main3.id]

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_db_instance" "dbinst" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "harish"
  password             = "harish2707"
  db_subnet_group_name = aws_db_subnet_group.dbgroup.id
  final_snapshot_identifier = "final-snapshot"
  skip_final_snapshot = true
}
# resource "aws_s3_bucket" "b" {
#   bucket = "terraformbuckhari"
#   acl    = "private"

#   tags = {
#     Name        = "cloud_bucket"
#     Environment = "default"
#   }
# }
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "terabuck"
    key            = "global/s3/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
  }
}"""
file = open("vpc.tf", "w") 
file.write(assignment) 
file.close()
os.system('terraform init')
os.system('terraform validate')
os.system('terraform plan')
os.system('terraform apply')
