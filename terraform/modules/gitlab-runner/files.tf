# https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/sensitive_file
data "local_sensitive_file" "gitlab_runner_micro_conf" {
    filename = "${path.module}/secrets/gitlab-runner/config.toml"
}


# To access EC2 VM via SSH
data "local_sensitive_file" "ec2_ley_pair_public" {
    filename = "${path.module}/secrets/ssh/ec2_key_pair.pub"
}