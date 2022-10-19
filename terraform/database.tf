resource "aws_db_subnet_group" "db_group" {
  name       = "db-subnet-group-${var.application_key}-${var.application_stage}"
  subnet_ids = [for subnet in aws_subnet.db : subnet.id]

  depends_on = [
    aws_subnet.db
  ]

  tags = {
    Name = "db-subnet-group-${var.application_key}-${var.application_stage}"
  }
}

resource "aws_rds_cluster" "database_cluster" {
  cluster_identifier        = "database-${var.application_key}-${var.application_stage}"
  engine                    = "postgres"
  engine_version            = "13.7"
  engine_mode               = "provisioned"
  database_name             = var.application_key
  master_username           = var.db_username
  master_password           = var.db_password
  vpc_security_group_ids    = [aws_security_group.rds.id]
  db_cluster_instance_class = var.db_instance_type

  allocated_storage = 100
  storage_type      = "io1"
  iops              = 1000

  skip_final_snapshot = true
  availability_zones  = var.availability_zones

  #final_snapshot_identifier = "backup-final-${var.application_key}-${var.application_stage}"

  db_subnet_group_name = aws_db_subnet_group.db_group.name

  tags = {
    Name = "database-${var.application_key}-${var.application_stage}"
  }

  lifecycle {
    ignore_changes = [cluster_identifier]
  }
}
