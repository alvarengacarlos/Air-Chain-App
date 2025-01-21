terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/27"
  tags = {
    Name        = "air-chain-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/28"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "air-chain-public-subnet"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.16/28"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "air-chain-private-subnet"
    Environment = var.environment
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "10.0.0.0/27"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name        = "air-chain-public-route-table"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "10.0.0.0/27"
    gateway_id = "local"
  }

  tags = {
    Name        = "air-chain-private-route-table"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.vpc.id

  subnet_ids = [aws_subnet.public_subnet.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 10
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 20
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 30
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 40
    action     = "allow"
    cidr_block = var.my_public_ip
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "tcp"
    rule_no    = 10
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 20
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 30
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name        = "air-chain-public-nacl"
    Environment = var.environment
  }
}

resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.vpc.id

  subnet_ids = [aws_subnet.private_subnet.id]

  tags = {
    Name        = "air-chain-private-nacl"
    Environment = var.environment
  }
}

resource "aws_security_group" "server_security_group" {
  name        = "air-chain-server-security-group"
  description = "Security Group for the server instance"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name        = "air-chain-server-security-group"
    Environment = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.server_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.server_security_group.id
  cidr_ipv4         = var.my_public_ip
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.server_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "server_instance" {
  ami                    = "ami-0df8c184d5f6ae949"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.server_security_group.id]
  subnet_id              = aws_subnet.public_subnet.id
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = 10
    volume_type           = "gp2"
  }
  key_name = "air-chain-server-instance-key-pair"

  tags = {
    Name        = "air-chain-server-instance"
    Environment = var.environment
  }
  user_data = <<EOF
#!/bin/bash
echo "Updating and Upgrading"
yum update
yum upgrade -y
yum install -y java-23-amazon-corretto
EOF
}

resource "aws_eip" "elastic_ip" {
  domain   = "vpc"
  instance = aws_instance.server_instance.id
  tags = {
    Name        = "air-chain-elastic-ip"
    Environment = var.environment
  }
  depends_on = [aws_internet_gateway.internet_gateway]
}
