
resource "aws_memorydb_subnet_group" "metamax_integrations" {
  name        = "cache-subnet-group"
  description = "Cache for ${local.environments[terraform.workspace]}-${var.namespace}"
  subnet_ids  = [for subnet in aws_subnet.db : subnet.id]

  tags = {
    Name        = "${local.environments[terraform.workspace]}-${var.namespace}-metamax_integrations"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_memorydb_cluster" "metamax_integrations" {
  # TODO: each service has own user and pass to login the server
  acl_name                 = "open-access"
  name                     = "metamax-integrations"
  node_type                = local.memorydb_types[terraform.workspace].node_type
  num_shards               = local.memorydb_types[terraform.workspace].num_shards
  num_replicas_per_shard   = local.memorydb_types[terraform.workspace].num_replicas_per_shard
  security_group_ids       = [aws_security_group.memory_db_for_redis.id]
  snapshot_retention_limit = local.memorydb_types[terraform.workspace].snapshot_retention_limit
  subnet_group_name        = aws_memorydb_subnet_group.metamax_integrations.id
  # TODO: enable tls
  tls_enabled = false

  tags = {
    Name        = "${local.environments[terraform.workspace]}-${var.namespace}-metamax-integrations"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


data "aws_memorydb_cluster" "metamax_integrations" {
  name = "metamax-integrations"

  depends_on = [
    aws_memorydb_cluster.metamax_integrations
  ]
}


