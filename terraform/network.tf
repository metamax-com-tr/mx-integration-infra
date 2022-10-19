data "aws_availability_zones" "available" {
  state = "available"
}

#VPC
resource "aws_vpc" "aws_vpc" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = {
    Name = "vpc-${var.application_key}-${var.application_stage}"
  }
}

#Internet Gateway For Public Subnet
resource "aws_internet_gateway" "igw" {
  vpc_id     = aws_vpc.aws_vpc.id
  depends_on = [aws_vpc.aws_vpc]
  tags       = {
    Name = "igw-${var.application_key}-${var.application_stage}"
  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.aws_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

#Elastic IP For NAT
data "aws_eip" "elastic_ip" {
  id = var.elastic_ip_allocation
}

#NAT
resource "aws_nat_gateway" "aws_natgw" {
  allocation_id = data.aws_eip.elastic_ip.id
  subnet_id     = element(aws_subnet.public.*.id, 0)
  depends_on    = [
    aws_internet_gateway.igw
  ]
  tags = {
    Name = "natgw-${var.application_key}-${var.application_stage}"
  }
}

# DB and Redis PRIVATE SUBNET
resource "aws_subnet" "db" {
  count             = length(var.availability_zones)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.aws_vpc.cidr_block, 4, count.index + 6)
  vpc_id            = aws_vpc.aws_vpc.id

  tags = {
    Name = "subnet-db-${var.application_key}-${var.application_stage}"
  }
}

# PRIVATE SUBNET
resource "aws_subnet" "backend" {
  count             = length(var.availability_zones)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.aws_vpc.cidr_block, 4, count.index + 3)
  vpc_id            = aws_vpc.aws_vpc.id

  tags = {
    Name = "subnet-backend-${var.application_key}-${var.application_stage}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create a new route table for the private subnets.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.aws_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.aws_natgw.id
  }
  tags = {
    Name = "private-rt-${var.application_key}-${var.application_stage}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# PUBLIC SUBNET
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.aws_vpc.cidr_block, 4, count.index)
  vpc_id                  = aws_vpc.aws_vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-public-${var.application_key}-${var.application_stage}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#================ Route Table Association for Private
resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = element(aws_subnet.backend.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}