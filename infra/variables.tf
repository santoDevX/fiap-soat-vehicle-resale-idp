# "variable" declara um parametro de entrada -- um valor que muda
# sem voce precisar editar o codigo dos recursos. Quem preenche o
# valor real e o arquivo terraform.tfvars (que voce cria, nao commita).

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  description = "Prefixo usado no nome de todos os recursos criados"
  type        = string
  default     = "vehicle-resale-idp"
}

# sensitive = true faz o Terraform esconder o valor nos logs
# e no output de "terraform plan", mas ainda fica visivel dentro
# do arquivo de state -- por isso o state tambem precisa ficar fora do Git.
variable "seed_admin_password" {
  description = "Senha do usuario admin.demo dentro do realm vehicle-resale"
  type        = string
  sensitive   = true
}

variable "provisioning_client_secret" {
  description = "Secret do client vehicle-resale-provisioning"
  type        = string
  sensitive   = true
}

variable "kc_bootstrap_admin_password" {
  description = "Senha do admin do CONSOLE do Keycloak (realm master, nao o admin.demo)"
  type        = string
  sensitive   = true
}