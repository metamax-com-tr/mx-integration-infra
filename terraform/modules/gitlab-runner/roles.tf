

resource "aws_iam_role" "artifact_deploy" {
  name = "gitlab_ci"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })


  tags = {
    Name = "Gitlab CI Role"
    Env  = "infra"
  }
}


resource "aws_iam_policy" "lambda_artifact_upload" {
  name        = "lambda_artifact_upload"
  description = "Uploding lambda artifact policy to S3 service"

  policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"",
         "Effect":"Allow",
         "Action":[
            "s3:PutAnalyticsConfiguration",
            "s3:PutAccelerateConfiguration",
            "s3:PutAccessPointConfigurationForObjectLambda",
            "s3:PutBucketOwnershipControls",
            "s3:PutObjectLegalHold",
            "s3:PutObject",
            "s3:PutBucketNotification",
            "s3:DeleteStorageLensConfiguration",
            "s3:PutBucketWebsite",
            "s3:PutBucketRequestPayment",
            "s3:PutObjectRetention",
            "s3:PutBucketLogging",
            "s3:PutBucketObjectLockConfiguration",
            "s3:PutBucketVersioning",
            "s3:ReplicateDelete"
         ],
         "Resource":"${aws_s3_bucket.artifact.arn}"
      },
      {
         "Sid":"",
         "Effect":"Allow",
         "Action":"s3:PutStorageLensConfiguration",
         "Resource":"${aws_s3_bucket.artifact.arn}"
      }
   ]
}
EOF

}

resource "aws_iam_group" "gitlab_ci" {
  name = "gitlab_ci"
}



resource "aws_iam_user" "gitlab_ci_user" {
  name = "gitlab_ci_user"
}



resource "aws_iam_policy_attachment" "test-attach" {
  name       = "gitlab_ci-attachment"
  users      = [aws_iam_user.gitlab_ci_user.name]
  roles      = [aws_iam_role.artifact_deploy.name]
  groups     = [aws_iam_group.gitlab_ci.name]
  policy_arn = aws_iam_policy.lambda_artifact_upload.arn
}