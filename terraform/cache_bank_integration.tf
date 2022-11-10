

data "aws_secretsmanager_secret_version" "vakifbank_statements_client_initial_version" {
  secret_id  = aws_secretsmanager_secret.vakifbank_statements_client.id
  version_id = aws_secretsmanager_secret_version.initial.version_id
}

resource "aws_memorydb_user" "metamax_integration_vakifbank_statements_client" {
  user_name     = jsondecode(data.aws_secretsmanager_secret_version.vakifbank_statements_client_initial_version.secret_string)["CACHE_USER"]
  access_string = "on ~* &* +@all"

  authentication_mode {
    type      = "password"
    passwords = [jsondecode(data.aws_secretsmanager_secret_version.vakifbank_statements_client_initial_version.secret_string)["CACHE_PASSWORD"]]
  }

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_memorydb_acl" "metamax_integrations" {
  name = "metamax-acl"
  user_names = [
    jsondecode(data.aws_secretsmanager_secret_version.vakifbank_statements_client_initial_version.secret_string)["CACHE_USER"]
  ]

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }

  depends_on = [
    aws_memorydb_user.metamax_integration_vakifbank_statements_client
  ]
}

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
  node_type                = "db.t4g.small"
  num_shards               = 1
  num_replicas_per_shard   = 1
  security_group_ids       = [aws_security_group.memory_db_for_redis.id]
  snapshot_retention_limit = 10
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


