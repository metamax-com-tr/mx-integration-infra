
resource "aws_memorydb_subnet_group" "cache_subnet_group" {
  name        = "cache-subnet-group"
  description = "Cache for ${local.environments[terraform.workspace]}-${var.namespace}"
  subnet_ids  = [for subnet in aws_subnet.db : subnet.id]

  tags = {
    Name        = "${local.environments[terraform.workspace]}-${var.namespace}-cache"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_memorydb_user" "metamax_user" {
  user_name     = jsondecode(data.aws_secretsmanager_secret_version.postgres_initial_version.secret_string)["CACHE_USER"]
  access_string = "on ~* &* +@all"

  authentication_mode {
    type      = "password"
    passwords = [jsondecode(data.aws_secretsmanager_secret_version.postgres_initial_version.secret_string)["CACHE_PASSWORD"]]
  }

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


resource "aws_memorydb_acl" "metamax" {
  name = "metamax-acl"
  user_names = [
    jsondecode(data.aws_secretsmanager_secret_version.postgres_initial_version.secret_string)["CACHE_USER"]
  ]

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }

  depends_on = [
    aws_memorydb_user.metamax_user
  ]
}

resource "aws_memorydb_cluster" "cluster" {
  acl_name                 = aws_memorydb_acl.metamax.name
  name                     = "metamax-cache-cluster"
  node_type                = "db.t4g.small"
  num_shards               = 1
  num_replicas_per_shard   = 1
  security_group_ids       = [aws_security_group.redis.id]
  snapshot_retention_limit = 7
  subnet_group_name        = aws_memorydb_subnet_group.cache_subnet_group.id

  tags = {
    Name        = "${local.environments[terraform.workspace]}-${var.namespace}-cache"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


data "aws_memorydb_cluster" "cluster" {
  name = "metamax-cache-cluster"

  depends_on = [
    aws_memorydb_cluster.cluster
  ]
}


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
