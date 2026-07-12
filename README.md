# HMCTS Case Management Backend

A Spring Boot service for caseworkers to track cases, containerised with Docker and deployed via a GitHub Actions CI/CD pipeline on Azure infrastructure defined with Terraform.

## Prerequisites

- Docker Desktop
- Java 21 (Temurin)
- Terraform >= 1.8

## Running Locally with Docker Compose

1. Clone the repository:
```bash
   git clone https://github.com/deepa-DevOps-26/hmcts-dev-test-backend
   cd hmcts-dev-test-backend
```

2. Create your environment file:
```bash
   cp .env.example .env
```

3. Start the application and database:
```bash
   docker compose up --build
```

4. Verify everything is running:
```bash
   curl http://localhost:4000/
   curl http://localhost:4000/health
   curl http://localhost:4000/get-example-case
```

The health endpoint will show `"db": {"status":"UP"}` confirming database connectivity.

To stop:
```bash
docker compose down
```

To stop and remove all data:
```bash
docker compose down -v
```

## CI/CD Pipeline

The pipeline is defined in `.github/workflows/ci.yml` and runs on every push to any branch.

### Stages

| Stage | What it does |
|---|---|
| `build-and-test` | Compiles the app, runs tests, and runs Checkstyle static analysis |
| `docker` | Builds the Docker image, pushes to GHCR, and scans for vulnerabilities with Trivy |
| `terraform` | Runs `terraform fmt -check` and `terraform validate` against the infrastructure code |

### Branch behaviour

- **Feature branches** — all jobs run but the Docker image is not pushed to the registry
- **master** — all jobs run and the Docker image is pushed to GitHub Container Registry (GHCR)

### Image tagging strategy

Images are tagged as `{branch}-{short-git-sha}` (e.g. `master-abc1234`). This gives:
- **Traceability** — you can see which branch produced the image
- **Immutability** — the SHA pinpoints the exact commit

### Security scanning

Trivy scans the container image for known vulnerabilities. The pipeline warns on CRITICAL and HIGH findings but does not block — in a production environment this would be configured to block on CRITICAL findings.

## Terraform Infrastructure

The infrastructure is defined in the `terraform/` directory and targets Microsoft Azure.

### Resources created

| Resource | Purpose |
|---|---|
| Resource Group | Container for all Azure resources |
| Azure Key Vault | Securely stores the database password |
| PostgreSQL Flexible Server | Managed database server (version 16) |
| PostgreSQL Database | The application database |
| Container App Environment | Platform for running containers |
| Container App | Runs the Spring Boot application |

### Why Container Apps over App Service?

Azure Container Apps is serverless-native, scales to zero (reducing costs in non-production environments), and is purpose-built for containers with built-in ingress and revision management.

### Secrets management

- The database password is defined as a `sensitive` variable in Terraform
- It is stored in Azure Key Vault and never appears in plain text in the repository
- The Container App reads the password from Key Vault at runtime

### State management

In a real deployment, Terraform state would be stored remotely using the `azurerm` backend with an Azure Storage Account. This provides:
- **Shared state** — all team members work from the same state
- **State locking** — prevents concurrent modifications
- **History** — full audit trail of infrastructure changes

The backend block is commented out in `versions.tf` so `terraform validate` runs locally without Azure credentials.

To enable it for real deployments, uncomment the backend block in `versions.tf`:
```hcl
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "stterraformstate"
  container_name       = "tfstate"
  key                  = "hmcts-backend/terraform.tfstate"
}
```

## Assumptions and Trade-offs

- **No SSL on local DB connection** — SSL enforcement is disabled locally for simplicity. In production `sslmode=require` would be added to the JDBC URL.
- **Trivy exit code set to 0** — the pipeline warns on vulnerabilities but does not block. In production it would block on CRITICAL findings.
- **No Azure account required** — `terraform validate` runs without credentials. `terraform plan` and `terraform apply` would require an Azure subscription.
- **Single revision mode** — the Container App uses single revision mode for simplicity. In production, multiple revisions would enable blue/green deployments.
- **With more time** — I would add integration tests, a staging environment, automated database migrations, and monitoring/alerting via Azure Monitor.
