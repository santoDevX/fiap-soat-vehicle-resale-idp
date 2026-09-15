# aws_apprunner_service e o recurso principal: ele cria o servico
# gerenciado que roda o container e expoe uma URL publica com HTTPS,
# sem voce precisar configurar load balancer, cluster ou certificado.
resource "aws_apprunner_service" "this" {
  service_name = var.project_name

  source_configuration {
    # Diz ao App Runner qual role usar pra puxar a imagem do ECR (iam.tf)
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_access.arn
    }

    # true = toda vez que uma imagem nova for enviada para a tag "latest"
    # no ECR, o App Runner redeploya sozinho, sem voce chamar nada manualmente.
    # NAO VERIFICADO: confirmar se isso e suficiente ou se o pipeline de
    # deploy.yml precisa chamar "aws apprunner start-deployment" explicitamente.
    auto_deployments_enabled = true

    image_repository {
      image_identifier      = "${aws_ecr_repository.this.repository_url}:latest"
      image_repository_type = "ECR"

      image_configuration {
        port = "8080" # porta que o Keycloak escuta dentro do container

        # Variaveis de ambiente comuns (nao secretas) passadas direto
        # pro container. Sem Secrets Manager aqui de proposito --
        # simplificacao aceita para este projeto academico.
        runtime_environment_variables = {
          KC_BOOTSTRAP_ADMIN_USERNAME = "admin"
          KC_BOOTSTRAP_ADMIN_PASSWORD = var.kc_bootstrap_admin_password
          SEED_PASSWORD               = var.seed_password
        }
      }
    }
  }

  # Quanto de CPU/memoria cada instancia do servico recebe.
  # 1 vCPU / 2GB e o minimo confortavel pro Keycloak nao travar.
  instance_configuration {
    cpu    = "1024" # 1024 = 1 vCPU, na unidade que a AWS usa
    memory = "2048" # em MB
  }

  # Como o App Runner verifica se o container esta saudavel.
  # TCP (so verifica se a porta responde) em vez de HTTP num path
  # especifico, porque nao confirmamos se /health/ready exige
  # --health-enabled=true nesta versao do Keycloak. TCP e mais
  # simples e nao quebra por causa de um path errado.
  health_check_configuration {
    protocol = "TCP"
  }
}