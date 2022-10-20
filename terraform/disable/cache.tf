resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name        = "cache-subnet-group-${var.application_key}-${var.application_stage}"
  subnet_ids  = [for subnet in aws_subnet.db : subnet.id]
  description = "Cache for ${var.application_key}-${var.application_stage}"

  depends_on = [
    aws_subnet.db
  ]

  tags = {
    Name = "cache-subnet-group-${var.application_key}-${var.application_stage}"
  }
}

resource "aws_elasticache_replication_group" "cache" {
  automatic_failover_enabled  = true
  multi_az_enabled            = true
  preferred_cache_cluster_azs = var.availability_zones
  replication_group_id        = "cache-${var.application_key}-${var.application_stage}"
  node_type                   = var.cache_instance_type
  description                 = "Cache for ${var.application_key}-${var.application_stage}"
  num_cache_clusters          = length(var.availability_zones)
  parameter_group_name        = "default.redis6.x"
  security_group_ids          = [aws_security_group.redis.id]
  subnet_group_name           = aws_elasticache_subnet_group.cache_subnet_group.name

  tags = {
    Name = "cache-${var.application_key}-${var.application_stage}"
  }
}
