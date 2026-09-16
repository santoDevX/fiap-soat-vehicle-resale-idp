#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Script de deploy: usado aqui no boot e depois via SSH manual, se precisar.
# Mantem a logica de deploy num unico lugar em vez de duplicar.
cat > /usr/local/bin/deploy-idp.sh <<'EOS'
#!/bin/bash
set -euo pipefail

AWS_REGION="${aws_region}"
ECR_REPOSITORY="${ecr_repository}"
APP_PORT="${app_port}"
KC_BOOTSTRAP_ADMIN_PASSWORD="${kc_bootstrap_admin_password}"
SEED_PASSWORD="${seed_password}"

# Retry: logo apos o boot, a credencial da instance role pode levar alguns
# segundos pra ficar disponivel via metadata. Sem isso, a primeira chamada
# aws cli falha e o script inteiro morre (cloud-init reporta "error").
retry() {
  local attempts=10 delay=6 i=1
  until "$@"; do
    if [ "$i" -ge "$attempts" ]; then
      echo "Falhou apos $attempts tentativas: $*" >&2
      return 1
    fi
    echo "Tentativa $i/$attempts falhou, tentando de novo em $${delay}s: $*" >&2
    sleep "$delay"
    i=$((i + 1))
  done
}

ACCOUNT_ID=$(retry aws sts get-caller-identity --query Account --output text --region "$AWS_REGION")
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

retry bash -c "aws ecr get-login-password --region '$AWS_REGION' | docker login --username AWS --password-stdin '$ECR_REGISTRY'"

retry docker pull "$ECR_REGISTRY/$ECR_REPOSITORY:latest"

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

# Primeiro (e, por enquanto, unico) deploy acontece no boot da instancia.
/usr/local/bin/deploy-idp.sh
