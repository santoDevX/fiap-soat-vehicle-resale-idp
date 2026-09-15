# ECR = onde a imagem Docker do Keycloak fica guardada na AWS.
# O GitHub Actions builda a imagem e da "docker push" pra esse repositorio;
# o App Runner (em apprunner.tf) puxa a imagem daqui para rodar.
resource "aws_ecr_repository" "this" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE" # permite reusar a tag "latest" a cada push

  image_scanning_configuration {
    scan_on_push = true # AWS escaneia a imagem por vulnerabilidades conhecidas
  }
}