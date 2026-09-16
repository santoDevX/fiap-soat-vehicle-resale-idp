# Chave gerada uma vez fora do Terraform (ssh-keygen) e distribuida via
# GitHub Secrets (EC2_SSH_PUBLIC_KEY / EC2_SSH_PRIVATE_KEY).
resource "aws_key_pair" "ec2" {
  key_name   = "${var.project_name}-key"
  public_key = var.ec2_ssh_public_key
}

# IP fixo: sem ele, a chave SSH do deploy.yml perderia o alvo toda vez que a
# instancia reiniciasse.
resource "aws_eip" "idp" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}

resource "aws_eip_association" "idp" {
  instance_id   = aws_instance.idp.id
  allocation_id = aws_eip.idp.id
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_instance" "idp" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = aws_key_pair.ec2.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  user_data = templatefile("${path.module}/scripts/user_data.sh.tpl", {
    aws_region                  = var.aws_region
    ecr_repository              = var.project_name
    app_port                    = var.app_port
    kc_bootstrap_admin_password = var.kc_bootstrap_admin_password
    seed_password               = var.seed_password
  })

  # IMDSv2 obrigatorio: exige token pra consultar o metadata service,
  # mitigando SSRF que tentaria roubar credenciais da instance role.
  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "${var.project_name}-idp"
  }
}
