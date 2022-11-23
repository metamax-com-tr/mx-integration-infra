
#VPC
resource "aws_vpc" "metamax_vpc" {
  cidr_block           = "11.0.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${var.environment}"
    Name        = "${var.environment}-metamax"
  }
}


# # Internet Gateway For Public Subnet
# resource "aws_internet_gateway" "igw" {
#   vpc_id     = aws_vpc.metamax_vpc.id
#   depends_on = [aws_vpc.metamax_vpc]
#   tags = {
#     Name        = "${local.environments[terraform.workspace]}-${var.namespace}"
#     NameSpace   = "${var.namespace}"
#     Environment = "${local.environments[terraform.workspace]}"
#   }
# }


# # Route the public subnet traffic through the IGW
# resource "aws_route" "internet_access" {
#   route_table_id         = aws_vpc.metamax_vpc.main_route_table_id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.igw.id
# }


# # Elastic IP For NAT
# # You first must allocate ip(s) on AWS console and you should add tag as the example follows
# # Name=development-metamax
# data "aws_eip" "elastic_ip" {
#   filter {
#     name   = "tag:Name"
#     values = ["${local.environments[terraform.workspace]}-${var.namespace}"]
#   }
# }


# ## outbound ip for metamax gateway
# data "aws_eip" "backend_outbound" {
#   filter {
#     name   = "tag:Name"
#     values = ["metamax-outbound-1"]
#   }
# }



# #NAT
# resource "aws_nat_gateway" "aws_natgw" {
#   allocation_id = data.aws_eip.elastic_ip.id
#   subnet_id     = element(aws_subnet.public.*.id, 0)
#   depends_on = [
#     aws_internet_gateway.igw
#   ]

#   tags = {
#     Name        = "${local.environments[terraform.workspace]}-load-balancer"
#     NameSpace   = "${var.namespace}"
#     Environment = "${local.environments[terraform.workspace]}"
#   }
# }

# # Back-end services need to access to internet, This is 
# # just outbound traffic. 
# resource "aws_nat_gateway" "backend_natgw" {
#   allocation_id = data.aws_eip.backend_outbound.id
#   subnet_id     = element(aws_subnet.firewall_subnet.*.id, 0)
#   depends_on = [
#     aws_internet_gateway.igw
#   ]

#   tags = {
#     Name        = "${local.environments[terraform.workspace]}-backend"
#     NameSpace   = "${var.namespace}"
#     Environment = "${local.environments[terraform.workspace]}"
#   }
# }



# PRIVATE SUBNET
resource "aws_subnet" "backend" {
  count                   = length(var.availability_zones)
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(aws_vpc.metamax_vpc.cidr_block, 5, count.index + 3)
  vpc_id                  = aws_vpc.metamax_vpc.id
  map_public_ip_on_launch = true


  tags = {
    Name        = "${var.environment}-${var.namespace}-backend"
    NameSpace   = "${var.namespace}"
    Environment = "${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}




# # PUBLIC SUBNET
# resource "aws_subnet" "public" {
#   count                   = length(local.availability_zones[terraform.workspace])
#   availability_zone       = local.availability_zones[terraform.workspace][count.index]
#   cidr_block              = cidrsubnet(aws_vpc.metamax_vpc.cidr_block, 6, count.index)
#   vpc_id                  = aws_vpc.metamax_vpc.id
#   map_public_ip_on_launch = true

#   tags = {
#     Name        = "${local.environments[terraform.workspace]}-${var.namespace}-public"
#     NameSpace   = "${var.namespace}"
#     Environment = "${local.environments[terraform.workspace]}"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # This is for NAT routing to internet for back-end services
# # References: 
# #- https://docs.aws.amazon.com/network-firewall/latest/developerguide/arch-igw-ngw.html
# resource "aws_subnet" "firewall_subnet" {
#   count                   = length(local.availability_zones[terraform.workspace])
#   availability_zone       = local.availability_zones[terraform.workspace][count.index]
#   cidr_block              = cidrsubnet(aws_vpc.metamax_vpc.cidr_block, 6, count.index + 15)
#   vpc_id                  = aws_vpc.metamax_vpc.id
#   map_public_ip_on_launch = true


#   tags = {
#     Name        = "${local.environments[terraform.workspace]}-${var.namespace}-firewall_subnet"
#     NameSpace   = "${var.namespace}"
#     Environment = "${local.environments[terraform.workspace]}"
#   }
#   lifecycle {
#     create_before_destroy = true
#   }
# }


# # DB and Redis PRIVATE SUBNET
# resource "aws_subnet" "db" {
#   count             = length(local.availability_zones[terraform.workspace])
#   availability_zone = local.availability_zones[terraform.workspace][count.index]
#   cidr_block        = cidrsubnet(aws_vpc.metamax_vpc.cidr_block, 6, count.index + 6)
#   # Example
#   #   > cidrsubnet("10.0.0.0/20", 1, 1)
#   #   "10.0.8.0/21"
#   #   > cidrsubnet("10.0.0.0/20", 2, 1)
#   #   "10.0.4.0/22"
#   #   > cidrsubnet("10.0.0.0/20", 3, 1)
#   #   "10.0.2.0/23"
#   #   > cidrsubnet("10.0.0.0/20", 4, 1)
#   #   "10.0.1.0/24"
#   #   > cidrsubnet("10.0.0.0/20", 4, 6)
#   #   "10.0.6.0/24"
#   #   > cidrsubnet("10.0.0.0/20", 4, 0)
#   #   "10.0.0.0/24"
#   #   "10.0.1.0/24"
#   #   > cidrsubnet("10.0.0.0/20", 4, 2)
#   #   "10.0.2.0/24"

#   vpc_id = aws_vpc.metamax_vpc.id

#   tags = {
#     Name        = "${local.environments[terraform.workspace]}-${var.namespace}-private-db"
#     NameSpace   = "${var.namespace}"
#     Environment = "${local.environments[terraform.workspace]}"
#   }
# }

# #================ Route Table Association for Private
# resource "aws_route_table_association" "backend" {
#   count          = length(local.availability_zones[terraform.workspace])
#   subnet_id      = element(aws_subnet.backend.*.id, count.index)
#   route_table_id = element(aws_route_table.backend.*.id, count.index)
# }

# # Create a new route table for the private subnets.
# resource "aws_route_table" "backend" {
#   vpc_id = aws_vpc.metamax_vpc.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.backend_natgw.id
#   }

#   tags = {
#     Name        = "${local.environments[terraform.workspace]}-${var.namespace}-backend"
#     NameSpace   = "${var.namespace}"
#     Environment = "${local.environments[terraform.workspace]}"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }



# # resource "aws_network_acl" "network_acl" {
# #   vpc_id     = aws_vpc.metamax_vpc.id
# #   subnet_ids = [for subnet in aws_subnet.public : subnet.id]
# #   tags = {
# #     Name        = "Metamax Network ACL "
# #     NameSpace   = "${var.namespace}"
# #     Environment = "${local.environments[terraform.workspace]}"
# #   }
# # }


# # resource "aws_network_acl_rule" "rule" {
# #   network_acl_id = aws_network_acl.network_acl.id
# #   count          = length(local.network_acl_rules[terraform.workspace])
# #   rule_number    = local.network_acl_rules[terraform.workspace][count.index].rule_number
# #   egress         = local.network_acl_rules[terraform.workspace][count.index].egress
# #   protocol       = local.network_acl_rules[terraform.workspace][count.index].protocol
# #   rule_action    = local.network_acl_rules[terraform.workspace][count.index].rule_action
# #   cidr_block     = local.network_acl_rules[terraform.workspace][count.index].cidr_block
# #   from_port      = local.network_acl_rules[terraform.workspace][count.index].from_port
# #   to_port        = local.network_acl_rules[terraform.workspace][count.index].to_port
# # }


