data "aws_availability_zones" "available" {
  state = "available"
}

#VPC
resource "aws_vpc" "aws_vpc" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
    Name        = "${local.environments[terraform.workspace]}-${var.namespace}"
  }
}


# DB and Redis PRIVATE SUBNET
resource "aws_subnet" "db" {
  count             = length(local.availability_zones[terraform.workspace])
  availability_zone = local.availability_zones[terraform.workspace][count.index]
  cidr_block        = cidrsubnet(aws_vpc.aws_vpc.cidr_block, 4, count.index + 6)
  # Example
  #   > cidrsubnet("10.0.0.0/20", 1, 1)
  #   "10.0.8.0/21"
  #   > cidrsubnet("10.0.0.0/20", 2, 1)
  #   "10.0.4.0/22"
  #   > cidrsubnet("10.0.0.0/20", 3, 1)
  #   "10.0.2.0/23"
  #   > cidrsubnet("10.0.0.0/20", 4, 1)
  #   "10.0.1.0/24"
  #   > cidrsubnet("10.0.0.0/20", 4, 6)
  #   "10.0.6.0/24"
  #   > cidrsubnet("10.0.0.0/20", 4, 6)
  #   "10.0.6.0/24"
  #   > cidrsubnet("10.0.0.0/20", 4, 0)
  #   "10.0.0.0/24"
  #   > cidrsubnet("10.0.0.0/20", 4, 1)
  #   "10.0.1.0/24"
  #   > cidrsubnet("10.0.0.0/20", 4, 2)
  #   "10.0.2.0/24"

  vpc_id = aws_vpc.aws_vpc.id

  tags = {
    Name        = "${local.environments[terraform.workspace]}-${var.namespace}-private-db"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


#Internet Gateway For Public Subnet
resource "aws_internet_gateway" "igw" {
  vpc_id     = aws_vpc.aws_vpc.id
  depends_on = [aws_vpc.aws_vpc]
  tags = {
    Name        = "${local.environments[terraform.workspace]}-${var.namespace}"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"

  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.aws_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# #Elastic IP For NAT
# data "aws_eip" "elastic_ip" {
#   id = var.elastic_ip_allocation
# }

# #NAT
# resource "aws_nat_gateway" "aws_natgw" {
#   allocation_id = data.aws_eip.elastic_ip.id
#   subnet_id     = element(aws_subnet.public.*.id, 0)
#   depends_on = [
#     aws_internet_gateway.igw
#   ]
#   tags = {
#     Name = "natgw-${var.application_key}-${var.application_stage}"
#   }
# }

# # DB and Redis PRIVATE SUBNET
# resource "aws_subnet" "db" {
#   count             = length(var.availability_zones)
#   availability_zone = data.aws_availability_zones.available.names[count.index]
#   cidr_block        = cidrsubnet(aws_vpc.aws_vpc.cidr_block, 4, count.index + 6)
#   vpc_id            = aws_vpc.aws_vpc.id

#   tags = {
#     Name = "subnet-db-${var.application_key}-${var.application_stage}"
#   }
# }

# # PRIVATE SUBNET
# resource "aws_subnet" "backend" {
#   count             = length(var.availability_zones)
#   availability_zone = data.aws_availability_zones.available.names[count.index]
#   cidr_block        = cidrsubnet(aws_vpc.aws_vpc.cidr_block, 4, count.index + 3)
#   vpc_id            = aws_vpc.aws_vpc.id

#   tags = {
#     Name = "subnet-backend-${var.application_key}-${var.application_stage}"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Create a new route table for the private subnets.
# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.aws_vpc.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.aws_natgw.id
#   }
#   tags = {
#     Name = "private-rt-${var.application_key}-${var.application_stage}"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # PUBLIC SUBNET
# resource "aws_subnet" "public" {
#   count                   = length(var.availability_zones)
#   availability_zone       = data.aws_availability_zones.available.names[count.index]
#   cidr_block              = cidrsubnet(aws_vpc.aws_vpc.cidr_block, 4, count.index)
#   vpc_id                  = aws_vpc.aws_vpc.id
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "subnet-public-${var.application_key}-${var.application_stage}"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# #================ Route Table Association for Private
# resource "aws_route_table_association" "private" {
#   count          = length(var.availability_zones)
#   subnet_id      = element(aws_subnet.backend.*.id, count.index)
#   route_table_id = element(aws_route_table.private.*.id, count.index)
# }