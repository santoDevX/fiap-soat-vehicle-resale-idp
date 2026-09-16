# fiap-soat-vehicle-resale-idp

Identity Provider standalone: Keycloak self-hosted, com autenticação e emissão de JWT via OAuth2/OIDC.

## O que é

Keycloak com um realm próprio (`vehicle-resale`), dois roles de negócio (`ADMIN`, `CUSTOMER`) e um client OAuth2 (`vehicle-resale-client`, público, usado por qualquer consumidor: Postman, frontend, outra API, para autenticar e obter um JWT).

O realm já vem com dois usuários seed:

| username | role | senha |
|---|---|---|
| `admin.demo` | `ADMIN` | `SEED_PASSWORD` |
| `customer.demo` | `CUSTOMER` | `SEED_PASSWORD` |

Self-registration está habilitado (`registrationAllowed: true`), então novos usuários também podem se cadastrar direto pelo Keycloak.

## Como foi implementado

- **Keycloak** roda em modo `start-dev`, com banco H2 embutido (sem dependência externa) e o realm importado automaticamente a partir de `keycloak/realm-export.json`.
- **CI** (`.github/workflows/ci.yml`): roda em todo Pull Request, valida o JSON do realm, builda a imagem (sem push) e roda `terraform fmt`/`terraform validate` em `/iac`.
- **Security scan** (`.github/workflows/security.yml`): roda em push e PR para `main`, escaneia o `/iac` com Trivy e publica o resultado no painel de segurança do GitHub.
- **Deploy** (`.github/workflows/deploy.yml`): a cada push em `main`, builda a imagem, dá push para o ECR e roda `terraform apply` em `/iac` (cria/atualiza EC2 que roda o container).
- **Infraestrutura** (`/iac`, Terraform): provisiona tudo na AWS. State remoto em S3 (compartilhado com o projeto `fiap-soat-vehicle-resale-api`, key própria). O `apply` roda no runner do GitHub Actions.

## Como rodar localmente

```bash
docker compose up -d
```

O Keycloak sobe em `http://localhost:8081`, já com o realm `vehicle-resale` importado e `SEED_PASSWORD=demo123`.

## Como testar

Login com um dos usuários seed:

```bash
curl -X POST http://localhost:8081/realms/vehicle-resale/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=vehicle-resale-client" \
  -d "username=customer.demo" \
  -d "password=demo123" \
  -d "grant_type=password"
```

O `access_token` retornado é um JWT assinado pelo realm `vehicle-resale`.

Os curls deste README funcionam do mesmo jeito em qualquer cliente REST (Bruno, Postman, Insomnia), é só montar o request equivalente.

Também há uma coleção Bruno pronta em `.bruno/IDP/`, com os requests de login (`admin.demo`, `customer.demo`), obtenção de token de admin e criação de usuário via Admin REST API. Para importar: no Bruno, clique em "+" no canto superior esquerdo, "Open Collection" e selecione a pasta `.bruno` (ou `.bruno/IDP`) deste repositório.
