# "variable" declara um parametro de entrada -- um valor que muda
# sem voce precisar editar o codigo dos recursos. No pipeline, cada
# TF_VAR_<nome> em deploy.yml preenche a variavel de mesmo nome aqui.

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "project_name" {
  description = "Prefixo usado no nome de todos os recursos criados"
  type        = string
  default     = "vehicle-resale-idp"
}

variable "instance_type" {
  description = "Tipo da instancia EC2 que roda o Keycloak. t3.micro e free tier (750h/mes nos primeiros 12 meses)."
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Porta em que o Keycloak escuta (mapeada 1:1 na EC2)."
  type        = number
  default     = 8080
}

variable "allowed_ssh_cidr" {
  description = "CIDR autorizado a acessar a porta 22 da EC2. Default liberado pra internet porque quem conecta e o runner do GitHub Actions (IP dinamico a cada execucao); o acesso continua exigindo a chave privada correspondente."
  type        = string
  default     = "0.0.0.0/0"
}

variable "ec2_ssh_public_key" {
  description = "Chave publica SSH (formato OpenSSH) autorizada na EC2. Gerada uma vez com ssh-keygen; vem do secret EC2_SSH_PUBLIC_KEY do GitHub Actions."
  type        = string
}

# sensitive = true faz o Terraform esconder o valor nos logs
# e no output de "terraform plan", mas ainda fica visivel dentro
# do arquivo de state -- por isso o state tambem precisa ficar fora do Git.
variable "seed_password" {
  description = "Senha do usuario admin.demo dentro do realm vehicle-resale"
  type        = string
  sensitive   = true
}

variable "kc_bootstrap_admin_password" {
  description = "Senha do admin do CONSOLE do Keycloak (realm master, nao o admin.demo)"
  type        = string
  sensitive   = true
}
