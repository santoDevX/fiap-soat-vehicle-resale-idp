#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Script de deploy: usado aqui no boot e depois via SSH pelo deploy.yml do
# GitHub Actions a cada push na main. Mantem a logica de deploy num unico
# lugar em vez de duplicar entre user_data e o workflow.
cat > /usr/local/bin/deploy-idp.sh <<'EOS'
#!/bin/bash
set -euxo pipefail

AWS_REGION="${aws_region}"
ECR_REPOSITORY="${ecr_repository}"
APP_PORT="${app_port}"
KC_BOOTSTRAP_ADMIN_PASSWORD="${kc_bootstrap_admin_password}"
SEED_PASSWORD="${seed_password}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region "$AWS_REGION")
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

docker pull "$ECR_REGISTRY/$ECR_REPOSITORY:latest"

docker stop vehicle-idp 2>/dev/null || true
docker rm vehicle-idp 2>/dev/null || true

docker run -d \
  --name vehicle-idp \
  --restart unless-stopped \
  -p "$APP_PORT":8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD="$KC_BOOTSTRAP_ADMIN_PASSWORD" \
  -e SEED_PASSWORD="$SEED_PASSWORD" \
  "$ECR_REGISTRY/$ECR_REPOSITORY:latest"
EOS

chmod +x /usr/local/bin/deploy-idp.sh

# Primeiro deploy acontece no boot da instancia
/usr/local/bin/deploy-idp.sh
