resource "tls_private_key" "ssh_bastion_key_private" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_bastion_key" {
  key_name   = "ssh_bastion_key-${var.application_key}-${var.application_stage}"
  public_key = tls_private_key.ssh_bastion_key_private.public_key_openssh
}

resource "aws_instance" "ssh_bastion" {
  ami           = "ami-065deacbcaac64cf2"
  instance_type = "t3.micro"

  associate_public_ip_address = true

  subnet_id              = aws_subnet.db[0].id
  vpc_security_group_ids = [aws_security_group.ssh_bastion.id]

  key_name = aws_key_pair.ssh_bastion_key.key_name

  user_data = <<EOF
              #!/bin/bash
              apt update
              apt install postgresql postgresql-client-12
              systemctl start postgresql.service
            EOF

  tags = {
    Name = "ssh-bastion-${var.application_key}-${var.application_stage}"
  }
}
