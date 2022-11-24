
resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-cache-subnet-group"
  subnet_ids  = [for subnet in aws_subnet.db : subnet.id]
  description = "${local.environments[terraform.workspace]}-${var.namespace} Cache for"

  depends_on = [
    aws_subnet.db
  ]

  tags = {
    Name        = "${local.environments[terraform.workspace]}-${var.namespace}-cache-subnet-group"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_elasticache_replication_group" "cache" {
  automatic_failover_enabled  = true
  multi_az_enabled            = true
  preferred_cache_cluster_azs = local.availability_zones[terraform.workspace]
  replication_group_id        = "cache-${local.environments[terraform.workspace]}-${var.namespace}"
  node_type                   = local.redis_types[terraform.workspace]
  description                 = "Cache for ${local.environments[terraform.workspace]}-${var.namespace}"
  num_cache_clusters          = length(local.availability_zones[terraform.workspace])
  parameter_group_name        = "default.redis6.x"
  security_group_ids          = [aws_security_group.redis.id]
  subnet_group_name           = aws_elasticache_subnet_group.cache_subnet_group.name


  tags = {
    Name        = "${local.environments[terraform.workspace]}-${var.namespace}-cache"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}
