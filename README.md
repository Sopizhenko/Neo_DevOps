# Lesson-8-9 — CI/CD Pipeline з Jenkins, Argo CD, Helm і Terraform

Повний CI/CD процес для Django-застосунку з використанням Jenkins, Helm, Terraform і Argo CD на AWS EKS.

## 🎯 Мета проєкту

Реалізувати повний CI/CD-процес, який:
1. Автоматично збирає Docker-образ для Django-застосунку
2. Публікує образ в Amazon ECR
3. Оновлює Helm chart у репозиторії з правильним тегом
4. Синхронізує застосунок у кластері через Argo CD


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
```

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
│   └── argo_cd/                # Argo CD Helm installation
│       ├── argo_cd.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── values.yaml
│       └── charts/             # Argo CD Application chart
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
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
- AWS Account з правами на створення EKS, ECR, VPC, S3

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
```


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

---

## 🧹 Очищення ресурсів

```bash
# Видалити Kubernetes ресурси
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
kubectl delete namespace jenkins argocd default

# Видалити Terraform ресурси
terraform destroy -auto-approve
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
```

---

## 📝 Примітки

- ✅ Jenkins використовує **Kaniko** для збірки образів без Docker daemon
- ✅ Argo CD налаштовано на **автоматичну синхронізацію** кожні 3 хвилини
- ✅ **HPA** автоматично масштабує pods при CPU > 70%
- ✅ **EBS CSI Driver** забезпечує persistent storage для Jenkins
- ✅ **LoadBalancer** services створюють AWS ELB автоматично
- ✅ Pipeline додає `[skip ci]` в commit message для уникнення циклів

---

## 🎯 Що реалізовано

✅ Terraform модулі для всієї інфраструктури  
✅ Jenkins з Kaniko для CI  
✅ Argo CD для CD  
✅ Helm charts для Django app  
✅ Автоматичне оновлення values.yaml  
✅ GitOps workflow  
✅ Auto-scaling (HPA)  
✅ Persistent storage (EBS CSI)  
✅ Load Balancing  

---
