resource "aws_ecr_repository" "internal" {
  name                 = "internal"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
