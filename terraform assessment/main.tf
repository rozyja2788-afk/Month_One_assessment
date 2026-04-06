terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-kernel-default-hvm-x86_64-gp2"
}

locals {
  az1 = data.aws_availability_zones.available.names[0]
  az2 = data.aws_availability_zones.available.names[1]

  common_tags = {
    Project     = var.project_name
    Environment = "assessment"
    ManagedBy   = "Terraform"
  }
}
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "techcorp-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "techcorp-igw"
  })
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = local.az1
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "techcorp-public-subnet-1"
    Tier = "public"
  })
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = local.az2
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "techcorp-public-subnet-2"
    Tier = "public"
  })
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = local.az1

  tags = merge(local.common_tags, {
    Name = "techcorp-private-subnet-1"
    Tier = "private"
  })
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = local.az2

  tags = merge(local.common_tags, {
    Name = "techcorp-private-subnet-2"
    Tier = "private"
  })
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "techcorp-public-rt"
  })
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_eip_1" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "techcorp-nat-eip-1"
  })
}

resource "aws_eip" "nat_eip_2" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "techcorp-nat-eip-2"
  })
}

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_1.id

  tags = merge(local.common_tags, {
    Name = "techcorp-nat-gw-1"
  })

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_2.id

  tags = merge(local.common_tags, {
    Name = "techcorp-nat-gw-2"
  })

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = merge(local.common_tags, {
    Name = "techcorp-private-rt-1"
  })
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }

  tags = merge(local.common_tags, {
    Name = "techcorp-private-rt-2"
  })
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}
resource "aws_security_group" "bastion_sg" {
  name        = "techcorp-bastion-sg"
  description = "Allow SSH from my IP only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "techcorp-bastion-sg"
  })
}

resource "aws_security_group" "alb_sg" {
  name        = "techcorp-alb-sg"
  description = "Allow HTTP and HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "techcorp-alb-sg"
  })
}

resource "aws_security_group" "web_sg" {
  name        = "techcorp-web-sg"
  description = "Allow web traffic from ALB and SSH from bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB SG"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "HTTPS from ALB SG"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "SSH from Bastion SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "techcorp-web-sg"
  })
}

resource "aws_security_group" "db_sg" {
  name        = "techcorp-db-sg"
  description = "Allow PostgreSQL from web SG and SSH from bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from Web SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    description     = "SSH from Bastion SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "techcorp-db-sg"
  })
}
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2.value
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true

  tags = merge(local.common_tags, {
    Name = "techcorp-bastion-host"
    Role = "bastion"
  })
}

resource "aws_eip" "bastion_eip" {
  domain   = "vpc"
  instance = aws_instance.bastion.id

  tags = merge(local.common_tags, {
    Name = "techcorp-bastion-eip"
  })
}

resource "aws_instance" "web_1" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2.value
  instance_type          = var.web_instance_type
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_pair_name
  user_data              = file("${path.module}/user_data/web_server_setup.sh")

  tags = merge(local.common_tags, {
    Name = "techcorp-web-server-1"
    Role = "web"
  })
}

resource "aws_instance" "web_2" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2.value
  instance_type          = var.web_instance_type
  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_pair_name
  user_data              = file("${path.module}/user_data/web_server_setup.sh")

  tags = merge(local.common_tags, {
    Name = "techcorp-web-server-2"
    Role = "web"
  })
}

resource "aws_instance" "db" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2.value
  instance_type          = var.db_instance_type
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = var.key_pair_name
  user_data              = file("${path.module}/user_data/db_server_setup.sh")

  tags = merge(local.common_tags, {
    Name = "techcorp-db-server"
    Role = "database"
  })
}

resource "aws_lb" "app_alb" {
  name               = "techcorp-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = merge(local.common_tags, {
    Name = "techcorp-app-alb"
  })
}

resource "aws_lb_target_group" "web_tg" {
  name     = "techcorp-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "techcorp-web-tg"
  })
}

resource "aws_lb_target_group_attachment" "web_1_attach" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_2_attach" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}