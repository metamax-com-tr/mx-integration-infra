resource "aws_db_subnet_group" "db_group" {
  name       = "${local.environments[terraform.workspace]}-${var.namespace}-postgresql"
  subnet_ids = [for subnet in aws_subnet.db : subnet.id]

  depends_on = [
    aws_subnet.db
  ]

  tags = {
    Name        = "${local.environments[terraform.workspace]}-${var.namespace}-db-subnet-group"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


data "aws_secretsmanager_secret_version" "postgres_initial_version" {
  secret_id = aws_secretsmanager_secret.postgres_sec.id
  version_id = aws_secretsmanager_secret_version.postgres_initial.version_id
}

resource "aws_db_instance" "database_instance" {
  db_name        = "metamax"
  engine         = "postgres"
  engine_version = "13.7"
  # TODO
  username               = jsondecode(data.aws_secretsmanager_secret_version.postgres_initial_version.secret_string)["DB_USER"]
  password               = jsondecode(data.aws_secretsmanager_secret_version.postgres_initial_version.secret_string)["DB_PASSWORD"]
  vpc_security_group_ids = [aws_security_group.rds.id]
  instance_class         = local.db_type[terraform.workspace].class
  multi_az               = local.db_type[terraform.workspace].multi_az
  db_subnet_group_name = aws_db_subnet_group.db_group.name

  allocated_storage   = local.db_type[terraform.workspace].allocated_storage
  skip_final_snapshot = true

  tags = {
    Name        = "${local.environments[terraform.workspace]}-${var.namespace}-database"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }

}