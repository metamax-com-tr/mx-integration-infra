output "Nat_Gateway_Public_Ip" {
  value = aws_nat_gateway.aws_natgw.public_ip
}

output "postgres_user" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.postgres_initial_version.secret_string)["DB_USER"]
  sensitive = true
}

output "postgres_pass" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.postgres_initial_version.secret_string)["DB_PASSWORD"]
  sensitive = true
}

# output "Console_Distribution_Id" {
#   value = aws_cloudfront_distribution.cloudfront_console.id
# }

# output "Web_Distribution_Id" {
#   value = aws_cloudfront_distribution.cloudfront_web.id
# }

# output "memorydb_redis_host" {
#   value = aws_memorydb_cluster.cluster.cluster_endpoint[0].address
# }

# output "memorydb_redis_port" {
#   value = aws_memorydb_cluster.cluster.cluster_endpoint[0].port
# }

# output "redis_host" {
#   value = aws_elasticache_replication_group.cache.primary_endpoint_address
# }

# output "redis_port" {
#   value = "6379"
# }

# output "db_host_endpoint" {
#   value = data.aws_db_instance.database_instance.endpoint
# }

# output "db_host_host" {
#   value = data.aws_db_instance.database_instance.address
# }

# output "db_host_port" {
#   value = data.aws_db_instance.database_instance.port
# }

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}