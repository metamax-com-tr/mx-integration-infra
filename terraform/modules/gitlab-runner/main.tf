

# SSH Key Pair 
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "${data.local_sensitive_file.ec2_ley_pair_public.content}"
}


# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/spot_instance_request
# # Request a spot instance at $0.0035
# resource "aws_spot_instance_request" "gitlabrunner" {

#     # Verified provider Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
#   ami           = "ami-0caef02b518350c8b"
#   instance_type = "t2.medium"


#   subnet_id              = aws_subnet.infra.id
#   vpc_security_group_ids = [aws_security_group.runner_ssh.id]
#   key_name = aws_key_pair.deployer.key_name

#   # root_block_device {
#   #   volume_type = "gp2"
#   #   volume_size = "8"
#   # }

#   # Spot Instance prices : https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#SpotInstances:
#   spot_price    = "0.017"
#   # Not working and I don't know the reason of yet!
#   wait_for_fulfillment  = false
  
#   user_data = <<-EOF
#     #!/bin/bash
#     sleep 30s
#     export DEBIAN_FRONTEND=noninteractive
#     apt-get update -y
#     apt-get upgrade -y
#     apt-get install openssh-server docker.io -y
#     systemctl enable ssh --now
#     curl -LJO https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_amd64.deb
#     dpkg -i gitlab-runner_amd64.deb
#     echo '${data.local_sensitive_file.gitlab_runner_micro_conf.content}' > /etc/gitlab-runner/config.toml
#     gitlab-runner restart
#     EOF

#   tags =  {
#     Name = "GitlabRunner"
#   }
# }



resource "aws_instance" "gitlabrunner" {

    # Verified provider Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
  ami           = "ami-0caef02b518350c8b"
  instance_type = "t2.medium"


  subnet_id              = aws_subnet.infra.id
  vpc_security_group_ids = [aws_security_group.runner_ssh.id]
  key_name = aws_key_pair.deployer.key_name

  root_block_device {
    volume_type = "gp2"
    volume_size = "80"
  }
  
  user_data = <<-EOF
    #!/bin/bash
    sleep 30s
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get upgrade -y
    apt-get install openssh-server docker.io -y
    systemctl enable ssh --now
    curl -LJO https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_amd64.deb
    dpkg -i gitlab-runner_amd64.deb
    echo '${data.local_sensitive_file.gitlab_runner_micro_conf.content}' > /etc/gitlab-runner/config.toml
    gitlab-runner restart
    EOF

  tags =  {
    Name = "GitlabRunner"
  }
}



# Getting data about account
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "current" {}
