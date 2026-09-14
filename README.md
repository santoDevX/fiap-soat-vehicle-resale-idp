# fiap-soat-vehicle-resale-idp

Identity Provider (Keycloak) totalmente apartado da API de vendas, atendendo ao requisito do enunciado de que o cadastro e a autorização de compradores fiquem separados dos dados transacionais.

## O que é

Keycloak self-hosted, com um realm próprio (`vehicle-resale`), dois roles de negócio (`ADMIN`, `CUSTOMER`) e dois clients OAuth2:

- `vehicle-resale-client`: usado por qualquer consumidor (Postman, frontend) para autenticar e obter um JWT.
- `vehicle-resale-provisioning`: usado só para criar usuários via Admin REST API, nunca pela API de vendas.

O repositório [`fiap-soat-vehicle-resale-api`](#) não tem nenhum código de autenticação. Ele só valida o JWT emitido aqui, via JWKS.

## Como rodar localmente

```bash
docker compose up --build
```

O Keycloak sobe em `http://localhost:8081`, já com o realm `vehicle-resale` importado.

## Como testar

### 1. Criar um cliente (cadastro)

```bash
# Obter token de servico do client de provisioning
curl -X POST http://localhost:8081/realms/vehicle-resale/protocol/openid-connect/token \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "client_id=vehicle-resale-provisioning" \
-d "client_secret=local-provisioning-secret" \
-d "grant_type=client_credentials"

# Criar o usuario (troque <ADMIN_TOKEN> pelo access_token retornado acima)
curl -X POST http://localhost:8081/admin/realms/vehicle-resale/users \
-H "Authorization: Bearer <ADMIN_TOKEN>" \
-H "Content-Type: application/json" \
-d '{"username":"cliente1","email":"cliente1@teste.com","enabled":true,"credentials":[{"type":"password","value":"senha123","temporary":false}]}'
```

Depois, atribua o role `CUSTOMER` ao usuário criado via Admin Console (`http://localhost:8081`, login `admin`/`admin_local_only`) ou via a API de role-mapping do Admin REST API.

### 2. Login do cliente

```bash
curl -X POST http://localhost:8081/realms/vehicle-resale/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=vehicle-resale-client" \
  -d "username=cliente1" \
  -d "password=senha123" \
  -d "grant_type=password"
```

O `access_token` retornado é o JWT usado no header `Authorization: Bearer` da API de vendas.

## Deploy

Automatizado via GitHub Actions (`.github/workflows/deploy.yml`): build da imagem, push para o ECR, `terraform apply` em `/infra`, deploy no AWS App Runner.

## Decisão de arquitetura

RDS público, protegido por senha forte e security group restrito à porta 5432. Trade-off aceito pelo prazo do projeto — ver `docs/adr/` (se presente) para detalhes e a alternativa correta (RDS em subnet privada com VPC connector).