output "Nat_Gateway_Public_Ip" {
  value = aws_nat_gateway.aws_natgw.public_ip
}

output "Database_Url" {
  value = aws_rds_cluster.database_cluster.endpoint
}

output "Cache_Url" {
  value = aws_elasticache_replication_group.cache.primary_endpoint_address
}

output "Container_Image_Registry" {
  value = aws_ecr_repository.backend_repository.repository_url
}

output "ECS_Cluster_Id" {
  value = aws_ecs_cluster.backend_cluster.id
}

output "Backend_Alb_Url" {
  value = aws_lb.load_balancer.dns_name
}

output "Lambda_Id" {
  value = aws_lambda_function.lambda_function.id
}

output "Console_Distribution_Id" {
  value = aws_cloudfront_distribution.cloudfront_console.id
}

output "Web_Distribution_Id" {
  value = aws_cloudfront_distribution.cloudfront_web.id
}

output "CDN_Bucket" {
  value = aws_s3_bucket.cdn_bucket.bucket_regional_domain_name
}

output "ECS_Task_Definition" {
  value = aws_ecs_task_definition.backend_cluster_tasks[*]
}

output "Codedeploy_Groups" {
  value = {for cj in var.backend_tasks : cj.application_name => aws_codedeploy_deployment_group.ecs_deploy_group[cj.application_name].deployment_group_name}
}


output "SSH_Bastion_Private_Key" {
  value     = tls_private_key.ssh_bastion_key_private.private_key_pem
  sensitive = true
}

output "SSH_Bastion_Public_Key" {
  value     = tls_private_key.ssh_bastion_key_private.public_key_openssh
}