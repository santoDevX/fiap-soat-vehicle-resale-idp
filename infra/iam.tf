# IAM = quem tem permissao pra fazer o que, na AWS.
# Aqui so precisamos de UMA role: a que da ao App Runner permissao
# de PUXAR a imagem do ECR (repositorio privado, exige autenticacao).
#
# Nao existe "instance role" neste repositorio porque o Keycloak,
# rodando aqui, nao chama nenhuma API da AWS em runtime (nao le
# Secrets Manager, nao grava em S3, nada). Instance role so seria
# necessaria se o container precisasse falar com outro servico AWS
# depois de already estar rodando.

# "assume_role_policy" = quem tem permissao de USAR essa role.
# O principal "build.apprunner.amazonaws.com" e o servico da AWS
# responsavel por buildar/puxar a imagem no processo de deploy do
# App Runner -- confirmado na documentacao oficial da AWS.
resource "aws_iam_role" "apprunner_access" {
  name = "${var.project_name}-apprunner-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "build.apprunner.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Anexa a essa role uma policy PRONTA da AWS (nao precisamos escrever
# a nossa) que da exatamente a permissao de ler imagens do ECR.
resource "aws_iam_role_policy_attachment" "apprunner_access" {
  role       = aws_iam_role.apprunner_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}