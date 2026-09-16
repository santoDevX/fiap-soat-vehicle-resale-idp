# Backend remoto: obrigatório porque quem roda "terraform apply" é o
# GitHub Actions (runner efêmero, uma máquina nova a cada execução). Sem
# state remoto, o Terraform perderia a memória do que já criou a cada run.
#
# Reaproveita o mesmo bucket S3 do projeto fiap-soat-vehicle-resale-api
# (mesma conta AWS), só que com uma "key" diferente — um bucket só pra
# guardar o state dos dois projetos, cada um na sua pasta lógica dentro
# dele.
#
# O bucket precisa existir antes do "terraform init". O próprio deploy.yml
# garante isso via AWS CLI (idempotente) antes de chamar o Terraform.
#
# use_lockfile = true usa o lock nativo do backend S3 (Terraform >= 1.10),
# sem precisar de uma tabela DynamoDB só pra isso.
terraform {
  backend "s3" {
    bucket       = "fiap-vehicle-resale-tfstate"
    key          = "vehicle-resale-idp/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
