resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "SG da EC2 que roda o Keycloak" # AWS exige description em ASCII puro
  vpc_id      = data.aws_vpc.default.id

  # trivy:ignore:AVD-AWS-0107 SSH aberto pra internet de proposito: quem
  # conecta e o runner do GitHub Actions, com IP dinamico a cada execucao.
  # O acesso continua exigindo a chave privada (sem senha), decisao
  # documentada em iac/README.md.
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Keycloak"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # trivy:ignore:AVD-AWS-0104 egress irrestrito de proposito: a instancia
  # precisa alcancar a internet (ECR, repositorios do dnf) sem VPC
  # endpoints dedicados, fora de escopo pra este projeto academico.
  egress {
    description = "Todo trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}
