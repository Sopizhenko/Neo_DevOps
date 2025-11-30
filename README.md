# Фінальний Проєкт DevOps — Повна AWS інфраструктура з CI/CD

Комплексне розгортання DevOps інфраструктури на AWS з використанням Terraform, що включає EKS, Jenkins, Argo CD, RDS/Aurora, ECR, та Prometheus/Grafana моніторинг.

## 🎯 Мета фінального проєкту

Реалізувати повноцінну production-ready DevOps інфраструктуру, що включає:
1. ✅ **Kubernetes кластер (EKS)** з підтримкою CI/CD
2. ✅ **Jenkins** для автоматизації збірки та деплою
3. ✅ **Argo CD** для GitOps управління застосунками
4. ✅ **RDS/Aurora** бази даних з високою доступністю
5. ✅ **ECR** контейнерний реєстр
6. ✅ **Prometheus & Grafana** для моніторингу та метрик
7. ✅ **Django застосунок** з автоматичним деплоєм


## 🏗️ Архітектура інфраструктури

```
AWS Cloud Infrastructure
│
├── VPC (10.0.0.0/16)
│   ├── Public Subnets (3 AZ: us-west-2a/b/c)
│   └── Private Subnets (3 AZ: us-west-2a/b/c)
│
├── EKS Cluster (lesson-7-eks)
│   ├── Node Group (t2.micro, 2-6 nodes)
│   ├── AWS EBS CSI Driver
│   └── Kubernetes v1.28+
│
├── RDS Databases
│   ├── PostgreSQL 14.7 (db.t3.micro) - Standard RDS
│   └── Aurora MySQL 8.0 (db.t3.small, 2 instances) - Cluster
│
├── ECR Repository (lesson-5-ecr)
│   └── Docker images for Django app
│
└── S3 + DynamoDB
    └── Terraform State Backend

Kubernetes Applications (in EKS)
│
├── jenkins (namespace)
│   └── Jenkins CI/CD Server + Kaniko builder
│
├── argocd (namespace)
│   └── Argo CD GitOps Controller + Applications
│
├── monitoring (namespace)
│   ├── Prometheus (metrics collection)
│   ├── Grafana (visualization & dashboards)
│   ├── Alertmanager (alerting)
│   └── Node Exporter + Kube State Metrics
│
└── default (namespace)
    └── Django App (managed by Argo CD)
        ├── Deployment (HPA enabled)
        ├── Service (LoadBalancer)
        └── ConfigMap (environment variables)
```

## 🔄 CI/CD Workflow

```
Developer Push → GitHub (lesson-7 branch)
                    ↓
          Jenkins detects change
                    ↓
        Build Docker Image (Kaniko)
                    ↓
          Push to Amazon ECR
                    ↓
    Update charts/django-app/values.yaml
                    ↓
        Commit & Push to GitHub
                    ↓
    Argo CD detects values.yaml change
                    ↓
      Auto-sync Django Deployment
                    ↓
  New Pods deployed with updated image
                    ↓
   Prometheus collects metrics → Grafana displays
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

## 📂 Структура фінального проєкту

```
lesson-5/
│
├── main.tf                      # Головний файл - підключення всіх модулів
├── backend.tf                   # S3 backend конфігурація для state
├── outputs.tf                   # Outputs для всіх компонентів
├── Jenkinsfile                  # Jenkins CI/CD pipeline
├── Dockerfile                   # Django app container image
├── requirements.txt             # Python dependencies
├── manage.py                    # Django management script
├── README.md                    # Ця документація
├── FINAL_PROJECT.md             # Детальна інструкція фінального проєкту
│
├── modules/                     # Terraform модулі
│   │
│   ├── s3-backend/             # S3 bucket + DynamoDB для state locking
│   │   ├── s3.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/                    # VPC, Subnets, Internet Gateway, Routes
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecr/                    # Amazon Elastic Container Registry
│   │   ├── ecr.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── eks/                    # EKS Cluster + Node Group + EBS CSI
│   │   ├── eks.tf
│   │   ├── aws_ebs_csi_driver.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── rds/                    # RDS PostgreSQL & Aurora MySQL
│   │   ├── variables.tf        # 29 змінних для гнучкої конфігурації
│   │   ├── shared.tf           # DB Subnet Group, Security Groups
│   │   ├── rds.tf              # Standard RDS instance
│   │   ├── aurora.tf           # Aurora Cluster з multiple instances
│   │   └── outputs.tf          # Connection strings, endpoints
│   │
│   ├── jenkins/                # Jenkins Helm chart deployment
│   │   ├── jenkins.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf        # Kubernetes + Helm providers
│   │   └── values.yaml         # Jenkins configuration
│   │
│   ├── argo_cd/                # Argo CD Helm chart + Applications
│   │   ├── argo_cd.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   ├── values.yaml         # Argo CD configuration
│   │   └── charts/             # Custom chart for Applications
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── application.yaml    # Django app Application CRD
│   │           └── repository.yaml     # Git repository config
│   │
│   └── monitoring/             # 🆕 Prometheus + Grafana (НОВИЙ МОДУЛЬ!)
│       ├── monitoring.tf       # Kube-Prometheus-Stack Helm release
│       ├── variables.tf        # Configuration variables
│       ├── outputs.tf          # URLs, passwords, port-forward commands
│       ├── providers.tf        # Kubernetes + Helm providers
│       └── values.yaml         # Prometheus & Grafana configuration
│
├── charts/                     # Helm charts
│   └── django-app/             # Django application Helm chart
│       ├── Chart.yaml
│       ├── values.yaml         # Image tag, replicas, resources
│       └── templates/
│           ├── deployment.yaml # Django Deployment with HPA
│           ├── service.yaml    # LoadBalancer Service
│           ├── configmap.yaml  # Environment variables
│           └── hpa.yaml        # Horizontal Pod Autoscaler
│
└── myproject/                  # Django application code
    ├── __init__.py
    ├── settings.py             # Django settings
    ├── urls.py                 # URL routing
    └── wsgi.py                 # WSGI application
```


## 📋 Передумови

### Необхідне програмне забезпечення:

- ✅ **AWS CLI** налаштовано з валідними credentials
- ✅ **Terraform** >= 1.6.0
- ✅ **kubectl** для роботи з Kubernetes
- ✅ **Helm** >= 3.0 для деплою charts
- ✅ **Git** для version control
- ✅ **AWS Account** з правами на створення:
  - EKS, VPC, EC2
  - RDS, Aurora
  - ECR
  - S3, DynamoDB
  - IAM Roles/Policies

### Перевірка встановлення:

```bash
# Перевірте версії
terraform --version    # >= 1.6.0
aws --version         # >= 2.0
kubectl version --client
helm version          # >= 3.0
git --version

# Налаштуйте AWS credentials
aws configure
# Введіть: Access Key ID, Secret Access Key, Region (us-west-2)

# Перевірка доступу до AWS
aws sts get-caller-identity
```

---

## 🚀 Розгортання інфраструктури

### ⚠️ ВАЖЛИВО: Розгортання відбувається у ДВА ЕТАПИ!

### Крок 1: Ініціалізація Terraform

```bash
cd /home/asopi/projects/lesson-5

# Ініціалізація Terraform (завантаження провайдерів)
terraform init -upgrade

# Перегляд плану (опціонально)
terraform plan
```

### Крок 2: Етап 1 - Базова інфраструктура

```bash
# Розгортаємо S3 Backend, VPC, ECR, EKS
terraform apply \
  -target=module.s3_backend \
  -target=module.vpc \
  -target=module.ecr \
  -target=module.eks \
  -auto-approve
```

**Що створюється:**
- ✅ S3 bucket `lesson-5-s3-back` для Terraform state
- ✅ DynamoDB table для state locking
- ✅ VPC з 3 публічними та 3 приватними підмережами
- ✅ ECR repository `lesson-5-ecr`
- ✅ EKS cluster `lesson-7-eks` з node group (2-6 nodes, t2.micro)
- ✅ AWS EBS CSI Driver для persistent volumes

⏱️ **Очікуваний час**: 15-20 хвилин

### Крок 3: Налаштування kubectl

```bash
# Отримання credentials для EKS кластера
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks

# Перевірка доступу до кластера
kubectl get nodes
kubectl get namespaces

# Очікуваний результат: 2+ nodes в Ready стані
```

### Крок 4: Етап 2 - Додаткові сервіси

```bash
# Розгортаємо RDS, Jenkins, Argo CD, Monitoring
terraform apply -auto-approve
```

**Що додається:**
- ✅ RDS PostgreSQL 14.7 (db.t3.micro)
- ✅ Aurora MySQL Cluster з 2 інстансами (db.t3.small)
- ✅ Jenkins через Helm (з Kaniko підтримкою)
- ✅ Argo CD через Helm (з автоматичною Application для Django)
- ✅ Prometheus + Grafana для моніторингу

⏱️ **Очікуваний час**: 20-25 хвилин

### Крок 5: Отримання інформації про ресурси

```bash
# Виведіть всі outputs
terraform output

# Отримайте конкретні значення
terraform output ecr_repository_url
terraform output eks_cluster_name
terraform output jenkins_url
terraform output argocd_url
terraform output grafana_url

# Отримайте паролі (вони sensitive)
terraform output -raw jenkins_admin_password
terraform output -raw argocd_admin_password
terraform output -raw grafana_admin_password

# Database connection strings
terraform output -raw postgres_connection_string
terraform output -raw aurora_connection_string
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
