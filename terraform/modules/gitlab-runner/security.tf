resource "aws_security_group" "runner_ssh" {
  name = "runner_ssh"
  vpc_id      = aws_vpc.gitlab_vpc.id
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    # Metamax VPN
    cidr_blocks = ["78.186.23.180/32"]
  }
  // connectivity to ubuntu mirrors is required to run `apt-get update` and `apt-get install apache2`
  # TODO: Security check
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
