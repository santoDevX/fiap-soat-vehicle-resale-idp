# "output" mostra valores depois que o terraform apply termina --
# util pra pegar informacao sem entrar no console da AWS.
# Rode "terraform output" a qualquer momento pra ver esses valores de novo.

output "ecr_repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "apprunner_service_url" {
  description = "URL publica do Keycloak -- e essa que vai no video e no README"
  value       = aws_apprunner_service.this.service_url
}