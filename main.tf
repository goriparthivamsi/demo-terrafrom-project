variable "access_key" {description = "access key of admin user"}
variable "secret_key" {description = "secret key of admin user"}
variable "region" {default = "us-east-1"}
variable "vpc_cidr" {description = "cidr block of vpc"}
variable "subnet_cidr_block" {}
variable "availability_zone" {}
variable "env_prefix" {}
variable "my_ip"{}


provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region

}
#creating a VPC
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr
  tags =  {
    Name = "${var.env_prefix}-vpc"
  }
}
#creating a subnet
resource "aws_subnet" "myapp-subnet-1" {
  cidr_block = var.subnet_cidr_block
  vpc_id = aws_vpc.myapp-vpc.id
  availability_zone = var.availability_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}
#creating a route table
resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}
#creating an internet gateway
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}
# associated route table with subnet
resource "aws_route_table_association" "a-rtb-subnet" {
  route_table_id = aws_route_table.myapp-route-table.id
  subnet_id = aws_subnet.myapp-subnet-1.id

}
#creating an aws security group
resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    protocol = "tcp"
    to_port = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name = "${var.env_prefix}-sg"
  }
}
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}
output "aws_ami" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

//resource "aws_key_pair" "ssh-key" {
//  key_name="server-key"
//  public_key = "${file(var.public_key_path)}"
//}

resource "aws_instance" "myapp-server" {

  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = "t2.micro"
  key_name="terraform_learning"
  security_groups = [aws_security_group.myapp-sg.id]
  subnet_id = aws_subnet.myapp-subnet-1.id
  tags = {
    Name = "${var.env_prefix}-app-server"
  }
  associate_public_ip_address = true
  user_data = <<EOF
               #!/bin/bash
                sudo yum update -y && sudo yum install -y docker
                sudo systemctl start docker
                sudo usermod -aG docker ec2-user
                newgrp docker
                docker run -p 8080:80 nginx:latest
              EOF
}
output "public-ip" {
  value = aws_instance.myapp-server.public_ip
}