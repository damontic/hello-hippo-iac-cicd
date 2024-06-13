resource "aws_ecr_repository" "hellohippo-golang" {
  name                 = "hellohippo/golang-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
