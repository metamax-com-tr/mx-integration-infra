
resource "aws_vpc" "gitlab_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "infra"
  }
}

resource "aws_internet_gateway" "infra_internet" {
  vpc_id = aws_vpc.gitlab_vpc.id

  tags = {
    Name = "infra"
  }
}

resource "aws_subnet" "infra" {
  vpc_id     = aws_vpc.gitlab_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "infra"
  }
}

resource "aws_route_table" "infra" {
  vpc_id = aws_vpc.gitlab_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.infra_internet.id
  }

  tags = {
    Name = "infra"
  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.gitlab_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.infra_internet.id
}

# if you want it to be reachable from the internet over IPv4.
resource "aws_eip" "lb" {
  instance = aws_instance.gitlabrunner.id
  vpc      = true
  tags = {
    Name = "gitlab-runner"
    Environment = "infra"
  }
}