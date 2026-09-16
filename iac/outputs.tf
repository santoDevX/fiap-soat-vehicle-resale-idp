# "output" mostra valores depois que o terraform apply termina --
# util pra pegar informacao sem entrar no console da AWS.
# Rode "terraform output" a qualquer momento pra ver esses valores de novo.

output "idp_public_ip" {
  description = "IP publico (fixo) da EC2 que roda o Keycloak."
  value       = aws_eip.idp.public_ip
}
