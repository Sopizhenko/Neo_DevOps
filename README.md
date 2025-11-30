# Lesson- 10 — CI/CD Pipeline з Jenkins, Argo CD, Helm, Terraform і RDS

Повний CI/CD процес для Django-застосунку з використанням Jenkins, Helm, Terraform, Argo CD та RDS/Aurora на AWS EKS.

## 🎯 Мета проєкту

Реалізувати повний CI/CD-процес з базами даних, який:
1. Автоматично збирає Docker-образ для Django-застосунку
2. Публікує образ в Amazon ECR
3. Оновлює Helm chart у репозиторії з правильним тегом
4. Синхронізує застосунок у кластері через Argo CD
5. Надає гнучку інфраструктуру баз даних (RDS або Aurora)


## 🏗️ Архітектура CI/CD

```
Developer Push → GitHub → Jenkins Pipeline → Build Image (Kaniko) → Push to ECR
                                          ↓
                                   Update values.yaml
                                          ↓
                                   Push to GitHub
                                          ↓
                              Argo CD detects change
                                          ↓
                              Deploy to EKS Cluster
                                          ↓
                              Connect to RDS/Aurora
```

## 🗄️ Архітектура баз даних

Модуль RDS підтримує два режими роботи:

**Standard RDS** (use_aurora = false):
- Один інстанс бази даних
- Підтримка Multi-AZ для високої доступності
- PostgreSQL або MySQL
- Ідеально для dev/test середовищ

**Aurora Cluster** (use_aurora = true):
- Кластер з декількох інстансів
- Автоматична реплікація
- Reader та Writer endpoints
- Ідеально для production навантажень

---

## 📂 Структура проєкту

```
lesson-5/
│
├── main.tf                      # Головний Terraform файл
├── backend.tf                   # S3 backend конфігурація
├── outputs.tf                   # Outputs для всіх модулів
├── Jenkinsfile                  # Jenkins CI pipeline
├── Dockerfile                   # Django app Dockerfile
├── requirements.txt             # Python dependencies
│
├── modules/
│   ├── s3-backend/             # S3 + DynamoDB для state
│   ├── vpc/                    # VPC, subnets, routing
│   ├── ecr/                    # ECR repository
│   ├── eks/                    # EKS cluster + EBS CSI Driver
│   │   ├── eks.tf
│   │   ├── aws_ebs_csi_driver.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── jenkins/                # Jenkins Helm installation
│   │   ├── jenkins.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── values.yaml
│   ├── argo_cd/                # Argo CD Helm installation
│   │   ├── argo_cd.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   ├── values.yaml
│   │   └── charts/             # Argo CD Application chart
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── application.yaml
│   │           └── repository.yaml
│   └── rds/                    # RDS/Aurora module (НОВИЙ!)
│       ├── variables.tf        # 29 змінних для конфігурації
│       ├── shared.tf           # DB Subnet Group, Security Group
│       ├── rds.tf              # Standard RDS resources
│       ├── aurora.tf           # Aurora Cluster resources
│       ├── outputs.tf          # Connection strings, endpoints
│       └── README.md           # Детальна документація
│
└── charts/
    └── django-app/             # Django Helm chart
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```


## 📋 Передумови

- AWS CLI налаштовано з валідними credentials
- Terraform >= 1.6.0
- kubectl
- Helm >= 3.0
- Git
- AWS Account з правами на створення EKS, ECR, VPC, S3, RDS

---

## 🚀 Встановлення

### Крок 1: Ініціалізація Terraform

```bash
cd /home/asopi/projects/lesson-5

# Ініціалізація Terraform
terraform init

# Перегляд плану
terraform plan

# Застосування конфігурації (створення всієї інфраструктури)
terraform apply -auto-approve
```

Цей процес створить:
- ✅ S3 bucket для Terraform state
- ✅ VPC з публічними та приватними підмережами
- ✅ ECR repository для Docker образів
- ✅ EKS cluster з node group
- ✅ EBS CSI Driver для persistent volumes
- ✅ Jenkins через Helm (з Kaniko підтримкою)
- ✅ Argo CD через Helm (з автоматичною Application)
- ✅ RDS PostgreSQL інстанс (Standard RDS)
- ✅ Aurora MySQL кластер з 2 інстансами

### Крок 2: Налаштування kubectl

```bash
# Отримання credentials для EKS
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks

# Перевірка доступу
kubectl get nodes
kubectl get namespaces
```

### Крок 3: Отримання URL та паролів

```bash
# Отримати всі outputs
terraform output

# Jenkins
terraform output jenkins_url
terraform output -raw jenkins_admin_password

# Argo CD
terraform output argocd_url
terraform output -raw argocd_admin_password

# ECR
terraform output ecr_repository_url

# RDS PostgreSQL (Standard)
terraform output rds_postgres_endpoint
terraform output rds_postgres_connection_string

# Aurora MySQL (Cluster)
terraform output rds_aurora_cluster_endpoint
terraform output rds_aurora_reader_endpoint
terraform output rds_aurora_connection_string
```

### Крок 4: Підключення до бази даних

```bash
# Отримати connection strings
POSTGRES_CONN=$(terraform output -raw rds_postgres_connection_string)
AURORA_CONN=$(terraform output -raw rds_aurora_connection_string)

echo "PostgreSQL: $POSTGRES_CONN"
echo "Aurora MySQL: $AURORA_CONN"

# Підключення через psql (PostgreSQL)
psql "$POSTGRES_CONN"

# Підключення через mysql (Aurora)
mysql -h <aurora-endpoint> -u admin -p mydatabase
```

---

## 🗄️ Конфігурація RDS

### Типи баз даних

Проєкт включає два приклади конфігурації:

**1. Standard RDS PostgreSQL** (`rds_postgres` модуль):
- PostgreSQL 14.7
- db.t3.micro
- 20 GB storage
- Multi-AZ для високої доступності
- Автоматичні backups (7 днів)

**2. Aurora MySQL Cluster** (`rds_aurora` модуль):
- Aurora MySQL 8.0.mysql_aurora.3.05.2
- 2 інстанси (Writer + Reader)
- db.t3.small
- Cluster endpoint + Reader endpoint
- Автоматичні backups (7 днів)

### Безпека

Обидві бази даних:
- ✅ Знаходяться в приватних підмережах
- ✅ Security Group дозволяє трафік лише з EKS nodes
- ✅ Encrypted at rest (AWS KMS)
- ✅ Encrypted in transit (SSL/TLS)
- ✅ Автоматичні security patches

### Використання в застосунку

Додайте в Django settings.py:

```python
import os

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'postgres'),
        'USER': os.environ.get('DB_USER', 'admin'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}
```

Оновіть `charts/django-app/templates/deployment.yaml`:

```yaml
env:
  - name: DB_HOST
    value: "<rds-endpoint>"  # з terraform output
  - name: DB_NAME
    value: "postgres"
  - name: DB_USER
    value: "admin"
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: password
```

### Додаткова документація

Для детальної інформації про RDS модуль:
- 📖 `modules/rds/README.md` - Повна документація модуля
- 📋 `RDS_QUICK_REFERENCE.md` - Швидкий довідник
- 📊 `RDS_HOMEWORK_SUMMARY.md` - Звіт про реалізацію

---

## 🔧 Конфігурація Jenkins

### 1. Доступ до Jenkins

```bash
# Отримати URL
JENKINS_URL=$(terraform output -raw jenkins_url)
echo "Jenkins URL: $JENKINS_URL"

# Отримати пароль
JENKINS_PASS=$(terraform output -raw jenkins_admin_password)
echo "Password: $JENKINS_PASS"
```

Логін: `admin` / Password: `admin123` (або з output)

### 2. Налаштування AWS Credentials

```
Jenkins → Manage Jenkins → Credentials → System → Global credentials → Add Credentials

Kind: AWS Credentials
ID: aws-credentials
Access Key ID: <your-aws-access-key>
Secret Access Key: <your-aws-secret-key>
```

### 3. Налаштування GitHub Credentials

```
Kind: Username with password
ID: github-credentials
Username: <your-github-username>
Password: <your-github-personal-access-token>
```

**Створення GitHub Token:**
1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Select scopes: `repo` (повний доступ)
4. Скопіюйте токен

### 4. Створення Pipeline

```
Jenkins → New Item
Name: django-app-pipeline
Type: Pipeline

Pipeline:
  Definition: Pipeline script from SCM
  SCM: Git
  Repository URL: https://github.com/Sopizhenko/Neo_DevOps.git
  Branch: lesson-8-9
  Script Path: Jenkinsfile
  
Save
```

### 5. Оновлення Jenkinsfile

Перед запуском pipeline оновіть змінні в `Jenkinsfile`:

```groovy
environment {
    ECR_REPO = "<ваш-ecr-url>"  // з terraform output ecr_repository_url
    GIT_REPO = 'https://github.com/Sopizhenko/Neo_DevOps.git'
    GIT_BRANCH = 'lesson-8-9'
}
```

---

## 🔄 Конфігурація Argo CD

### 1. Доступ до Argo CD

```bash
# Отримати URL
ARGOCD_URL=$(terraform output -raw argocd_url)
echo "Argo CD URL: $ARGOCD_URL"

# Отримати пароль
ARGOCD_PASS=$(terraform output -raw argocd_admin_password)
echo "Password: $ARGOCD_PASS"
```

Логін: `admin` / Password: `<з output>`

### 2. Перевірка Application

Argo CD автоматично створює Application `django-app`:

```bash
# Перевірка через kubectl
kubectl get applications -n argocd

# Детальна інформація
kubectl describe application django-app -n argocd
```

### 3. Manual Sync (за потреби)

```bash
# Через UI
Argo CD UI → Applications → django-app → Sync

# Через CLI
argocd app sync django-app
```

---

## 🔨 Використання CI/CD Pipeline

### Запуск Pipeline

1. Перейдіть до Jenkins → django-app-pipeline
2. Натисніть "Build Now"

### Pipeline Stages:

1. **Checkout Code** - Клонує репозиторій
2. **Build Docker Image** - Збирає образ через Kaniko (без Docker daemon)
3. **Push to ECR** - Публікує образ в ECR з тегом = BUILD_NUMBER
4. **Update Helm Values** - Оновлює `tag` в charts/django-app/values.yaml
5. **Push Changes** - Комітить і пушить зміни в GitHub

### Автоматична синхронізація

Після оновлення `values.yaml`:
1. ⏱️ Argo CD виявляє зміни (кожні 3 хвилини)
2. 🔄 Автоматично синхронізує застосунок
3. 🚀 Kubernetes створює нові pods з новим образом
4. ♻️ Старі pods видаляються після успішного запуску

---

## ✅ Перевірка роботи

### Перевірка Jenkins

```bash
kubectl get pods -n jenkins
kubectl logs -n jenkins -l app.kubernetes.io/name=jenkins
```

### Перевірка Argo CD

```bash
kubectl get pods -n argocd
kubectl get application -n argocd
kubectl describe application django-app -n argocd
```

### Перевірка Django App

```bash
# Deployment та Pods
kubectl get deployments
kubectl get pods -l app=django-app

# Service
kubectl get svc django-app-service

# Load Balancer URL
DJANGO_URL=$(kubectl get svc django-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Django App: http://$DJANGO_URL"

# Тест доступності
curl http://$DJANGO_URL
```

---

## 🐛 Troubleshooting

### Jenkins не може push в ECR

```bash
# Перевірте credentials
kubectl get secrets -n jenkins

# Перевірте ECR policy
aws ecr get-repository-policy --repository-name lesson-5-ecr --region us-west-2
```

### Argo CD не синхронізує

```bash
# Логи
kubectl logs -n argocd deployment/argocd-repo-server
kubectl logs -n argocd deployment/argocd-application-controller

# Примусова синхронізація
argocd app sync django-app --force
```

### Pods не запускаються

```bash
kubectl get events --sort-by='.lastTimestamp'
kubectl logs <pod-name>
kubectl describe pod <pod-name>
```

### Image pull errors

```bash
# Перевірка образів в ECR
aws ecr list-images --repository-name lesson-5-ecr --region us-west-2

# Перевірка тегу в values.yaml
cat charts/django-app/values.yaml | grep tag
```

### RDS Connection issues

```bash
# Перевірка endpoints
terraform output | grep endpoint

# Перевірка Security Groups
kubectl get nodes -o wide  # Отримати Node IPs
aws ec2 describe-security-groups --group-ids <rds-sg-id>

# Тест з'єднання з pod
kubectl run -it --rm debug --image=postgres:14 --restart=Never -- \
  psql "postgresql://admin:YourPassword@<endpoint>:5432/postgres"

# Для MySQL/Aurora
kubectl run -it --rm debug --image=mysql:8.0 --restart=Never -- \
  mysql -h <endpoint> -u admin -p
```

---

## 🧹 Очищення ресурсів

```bash
# Видалити Kubernetes ресурси
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
kubectl delete namespace jenkins argocd default

# ВАЖЛИВО: Видалити RDS snapshots (якщо потрібно)
aws rds describe-db-snapshots --query 'DBSnapshots[?contains(DBInstanceIdentifier, `lesson-8-9`)].DBSnapshotIdentifier'
# Видалити кожен snapshot окремо
# aws rds delete-db-snapshot --db-snapshot-identifier <snapshot-id>

# Видалити Terraform ресурси
terraform destroy -auto-approve
```

**Примітка:** RDS створює final snapshot при видаленні. Щоб пропустити:
```hcl
# В modules/rds/rds.tf та aurora.tf
skip_final_snapshot = true  # Змініть з false на true для тестування
```

---

## 📚 Корисні команди

```bash
# Перевірка всіх ресурсів
kubectl get all --all-namespaces

# Перевірка storage
kubectl get storageclass
kubectl get pvc --all-namespaces

# Restart Jenkins
kubectl rollout restart deployment jenkins -n jenkins

# Restart Argo CD
kubectl rollout restart deployment -n argocd

# Масштабування Django app
kubectl scale deployment django-app-deployment --replicas=4

# HPA status
kubectl get hpa

# Перевірка RDS статусу
aws rds describe-db-instances --db-instance-identifier lesson-8-9-postgres
aws rds describe-db-clusters --db-cluster-identifier lesson-8-9-aurora

# Список всіх баз даних
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine]'
aws rds describe-db-clusters --query 'DBClusters[*].[DBClusterIdentifier,Status,Engine]'
```

---

## 📝 Примітки

- ✅ Jenkins використовує **Kaniko** для збірки образів без Docker daemon
- ✅ Argo CD налаштовано на **автоматичну синхронізацію** кожні 3 хвилини
- ✅ **HPA** автоматично масштабує pods при CPU > 70%
- ✅ **EBS CSI Driver** забезпечує persistent storage для Jenkins
- ✅ **LoadBalancer** services створюють AWS ELB автоматично
- ✅ Pipeline додає `[skip ci]` в commit message для уникнення циклів
- ✅ **RDS модуль** підтримує як Standard RDS, так і Aurora кластери
- ✅ Бази даних **ізольовані** в приватних підмережах
- ✅ Доступ до RDS лише з **EKS node security group**
- ✅ **Автоматичні backups** та **encryption** увімкнено за замовчуванням

---     
