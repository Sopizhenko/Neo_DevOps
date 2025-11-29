# lesson-5 – Terraform AWS Infrastructure

Цей проект створює базову інфраструктуру в AWS за допомогою Terraform:

- S3 бакет + DynamoDB таблиця для бекенду стейтів Terraform
- VPC з публічними та приватними підмережами, IGW та NAT Gateway
- ECR репозиторій для Docker-образів

## Структура проекту

- `main.tf` – підключення провайдера та модулів (`s3-backend`, `vpc`, `ecr`)
- `backend.tf` – конфігурація бекенду Terraform (S3 + DynamoDB)
- `outputs.tf` – загальні вихідні дані (агрегація модульних output-ів)
- `modules/s3-backend` – модуль для S3 бакета та DynamoDB таблиці
- `modules/vpc` – модуль мережевої інфраструктури (VPC, subnets, routes, IGW, NAT)
- `modules/ecr` – модуль для ECR репозиторію

## Команди для запуску

```bash
1. Ініціалізація Terraform: terraform init

2. Перегляд плану змін: terraform plan

3. Застосування змін: terraform apply

4. идалення створених ресурсів: terraform destroy
