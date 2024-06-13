data "aws_ecr_image" "golang-app-lightsail" {
  repository_name = aws_ecr_repository.hellohippo-golang.name
  image_tag       = "0.0.2"
}

data "aws_iam_policy_document" "lightsail_ecr" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_lightsail_container_service.golang_app.private_registry_access[0].ecr_image_puller_role[0].principal_arn]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
  }
}

resource "aws_ecr_repository_policy" "lightsail_ecr" {
  repository = aws_ecr_repository.hellohippo-golang.name
  policy     = data.aws_iam_policy_document.lightsail_ecr.json
}

resource "aws_lightsail_container_service" "golang_app" {
  name        = "golang-app"
  power       = "nano"
  scale       = 1
  is_disabled = false

  private_registry_access {
    ecr_image_puller_role {
      is_active = true
    }
  }

  tags = {
    name = "golang-app"
  }
}

resource "aws_lightsail_container_service_deployment_version" "golang_app" {
  container {
    container_name = "golang-app"
    image          = data.aws_ecr_image.golang-app-lightsail.image_uri

    environment = {
      PORT = "8080"
    }

    ports = {
      8080 = "HTTP"
    }
  }

  public_endpoint {
    container_name = "golang-app"
    container_port = 8080

    health_check {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout_seconds     = 2
      interval_seconds    = 5
      path                = "/"
      success_codes       = "200-499"
    }
  }

  service_name = aws_lightsail_container_service.golang_app.name
}