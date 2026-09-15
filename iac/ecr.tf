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

# Sem isso o repositorio cresce pra sempre: cada push do deploy.yml cria uma
# tag nova com o SHA do commit (alem de atualizar "latest"), so pra permitir
# rollback manual. A tag "latest" fica protegida (regra 1, nunca expira porque
# so existe uma imagem com essa tag por vez); as demais expiram em 14 dias.
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Manter a tag latest indefinidamente"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expirar as demais imagens (tags de SHA e imagens sem tag) apos 14 dias"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}