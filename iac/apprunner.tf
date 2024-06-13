resource "aws_iam_role_policy" "app_runner_ecr_access" {
  name = "app_runner_ecr_access"
  role = aws_iam_role.app_runner_ecr_access.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
        {
        "Effect": "Allow",
        "Action": [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchGetImage",
            "ecr:DescribeImages",
            "ecr:GetAuthorizationToken"
        ],
        "Resource": "*"
        }
    ]
    })
}

resource "aws_iam_role" "app_runner_ecr_access" {
  name = "app_runner_ecr_access"

  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "build.apprunner.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
})
}

data "aws_ecr_image" "golang-app" {
  repository_name = aws_ecr_repository.hellohippo-golang.name
  image_tag       = "0.0.1"
}

resource "aws_apprunner_service" "golang-app" {
  service_name = "golang-app-service"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_ecr_access.arn
    }
    image_repository {
      image_configuration {
        port = "8080"
        runtime_environment_variables = {
            PORT = "8080"
        }
      }
      image_identifier      = data.aws_ecr_image.golang-app.image_uri
      image_repository_type = "ECR"
    }
    auto_deployments_enabled = false
  }

  tags = {
    Name = "golang-app-service"
  }
}
