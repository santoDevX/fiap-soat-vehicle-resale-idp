# Trava a versao minima do Terraform e do provider da AWS,
# para o comportamento nao mudar sem voce perceber.
terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Diz ao provider em qual regiao da AWS criar tudo.
provider "aws" {
  region = var.aws_region
}