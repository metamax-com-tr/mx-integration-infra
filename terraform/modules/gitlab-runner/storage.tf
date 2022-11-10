

resource "random_string" "s3_bucket_random_suffix" {
  length           = 6
  special          = true
  lower            = true
  upper            = false
  override_special = "-"
}

resource "aws_s3_bucket" "artifact" {
  bucket = "artifacts-${random_string.s3_bucket_random_suffix.id}"

  tags = {
    Name        = "Infra"
    Description = "The repo of the artifacts"
    Environment = "None"
  }
}

resource "aws_s3_bucket_acl" "artifact" {
  bucket = aws_s3_bucket.artifact.id
  acl    = "private"
}
