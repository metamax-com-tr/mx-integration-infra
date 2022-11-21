output "gitlabrunner_instance_id" {
  value = aws_instance.gitlabrunner.id
}

output "gitlabrunner_public_ip" {
  value       = aws_instance.gitlabrunner.public_ip
  description = "The public IP of the web server"
}


output "lambda_artifact_bucket" {
  description = "The bucket for the artifacts of the Lambda function"
  value = aws_s3_bucket.artifact.id
}
