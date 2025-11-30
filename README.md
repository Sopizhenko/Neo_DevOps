# Lesson-7 — Kubernetes (EKS) + ECR + Helm Deployment

Цей проєкт є продовженням попереднього домашнього завдання **lesson-5** і розширює інфраструктуру AWS, додаючи Kubernetes-кластер (EKS), репозиторій ECR та деплой Django-застосунку через Helm.

---

## 📂 Структура проєкту

```
lesson-7/
│
├── main.tf               # Підключення модулів та опис ресурсів
├── backend.tf            # Бекенд Terraform state (S3)
├── outputs.tf            # Виводи інфраструктури
│
├── modules/
│   ├── s3-backend/       # Імпорт існуючих S3 та DynamoDB ресурсів (з lesson-5)
│   ├── vpc/              # Мережевий модуль (VPC, subnets, routing)
│   ├── ecr/              # AWS Elastic Container Registry
│   └── eks/              # AWS EKS Kubernetes кластер
│
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```

> Модулі `vpc` та `ecr` можуть бути перенесені з `lesson-5`.  
> Модуль `s3-backend` описує існуючі ресурси, а не створює їх.

---

## ☁️ 1. Terraform Backend (S3 + DynamoDB)

Файл `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "lesson-5-s3-back"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    use_lockfile   = true
  }
}
```

---

## ☸️ 2. Kubernetes (EKS) кластер через Terraform

Після `terraform apply` створюється:

- EKS Control Plane  
- Node Group (EC2)  
- IAM ролі кластера та нод  
- Підключення до приватних subnet-ів VPC  

### Підключення до кластеру:

```bash
aws eks update-kubeconfig --name lesson-7-eks --region us-west-2
kubectl get nodes
```

---

## 🐳 3. Створення та пуш Docker-образу Django в ECR

Після створення репозиторію Terraform виведе його URL.

### Логін у ECR:

```bash
aws ecr get-login-password --region us-west-2   | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com
```

### Збірка:

```bash
docker build -t django-app .
```

### Тегування:

```bash
docker tag django-app:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr:latest
```

### Пуш:

```bash
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr:latest
```

---

## 📦 4. Helm-чарт Django

Helm-чарт знаходиться у:

```
charts/django-app/
```

Містить templates:

- **deployment.yaml** — деплой Django з envFrom ConfigMap  
- **service.yaml** — LoadBalancer для доступу до застосунку  
- **configmap.yaml** — змінні середовища  
- **hpa.yaml** — autoscaling (2–6 реплік, CPU > 70%)  

---

## 🧾 5. values.yaml

```yaml
image:
  repository: "<AWS_ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr"
  tag: "latest"

service:
  port: 80
  targetPort: 8000

env:
  DJANGO_SECRET_KEY: "supersecret"
  DEBUG: "false"
  DATABASE_URL: "postgres://user:pass@db:5432/app"

autoscaling:
  minReplicas: 2
  maxReplicas: 6
  targetCPU: 70
```

---

## 🚀 6. Deployment у Kubernetes

### Деплой:

```bash
helm install django-app ./charts/django-app
```

### Перевірити ресурси:

```bash
kubectl get pods
kubectl get svc
kubectl get hpa
kubectl describe configmap django-app-config
```

---

## 📝 7. Команди Terraform

```bash
terraform init
terraform plan
terraform apply
```
