# 🛠️ ApexPOS DevOps Infrastructure & Configuration Hub

Welcome to the **ApexPOS DevOps Infrastructure** repository. This project centralizes all operations, Infrastructure as Code (IaC), GitOps continuous delivery (CD), and Helm packaging configurations to run the ApexPOS MERN SaaS platform at scale.

---

## 🏛️ Directory Structure Overview

```text
├── .github/workflows/
│   └── validate.yml          # GitHub Actions pipeline (yamllint, hadolint, helm lint)
├── helm/
│   └── apexpos/              # Helm chart packaging for Frontend, Backend, & MongoDB
│       ├── templates/        # Kubernetes resource templates
│       ├── Chart.yaml        # Chart metadata
│       └── values.yaml       # Global deployment configurations
├── k8s/                      # Raw Kubernetes manifests (Alternative to Helm)
│   ├── backend/              # Node/Express API deployments & secrets
│   ├── database/             # MongoDB stateful PVCs & pods
│   ├── frontend/             # Nginx unprivileged React SPA deployments
│   ├── argocd-app.yml        # Argo CD GitOps Application manifest
│   └── namespace.yml         # Shared namespace declaration
├── terraform/                # Infrastructure as Code for AWS Provisioning
│   ├── providers.tf          # AWS version constraints
│   ├── variables.tf          # Parameterized variables (regions, instance sizes)
│   ├── vpc.tf                # VPC, subnets, NAT Gateway, routes
│   ├── security_groups.tf    # Restricted ports configuration (22, 80, 443, NodePorts)
│   ├── ec2.tf                # Bootstrapping instance with K3s, Docker, and Helm
│   └── outputs.tf            # Command outputs (IP, SSH helpers)
├── docker-compose-app.yml    # Runs application containers locally (Frontend/Backend/DB)
├── docker-compose-infra.yml  # Runs DevOps sandboxes locally (Jenkins, SonarQube, Registry)
└── Dockerfile-jenkins        # Custom Jenkins Dockerfile containing kubectl, Node, & plugins
```

---

## 🚀 1. Local Sandboxing & Infrastructure (Docker Compose)

We provide a complete sandbox containing **Jenkins**, **SonarQube**, and a local **Docker Registry** to develop and test pipelines locally without paying for cloud resources.

### Run Local Infrastructure
To spin up Jenkins and SonarQube:
```bash
docker compose -f docker-compose-infra.yml up -d
```
- **Jenkins Dashboard**: `http://localhost:8085` (Security disabled automatically for local convenience)
- **SonarQube Server**: `http://localhost:9000` (Used for code quality scanning)
- **Local Docker Registry**: `http://localhost:5000` (Allows pushes from Jenkins)

### Run Local Application
To spin up frontend, backend, and MongoDB database containers using Docker Compose:
```bash
docker compose -f docker-compose-app.yml up -d
```
- **Frontend Dashboard**: `http://localhost`
- **Backend API Server**: `http://localhost:5000`
- **MongoDB Instance**: `localhost:27017`

---

## ⛵ 2. Kubernetes Packaging with Helm

We package the entire stack (Frontend, Backend, and MongoDB) into a standard Helm Chart. This allows dynamic environment management (Staging vs. Production) and simple release rollbacks.

### Validate Chart
```bash
helm lint helm/apexpos/
```

### Install Application
Deploy the entire platform into the `apexpos` namespace:
```bash
helm install apexpos-prod helm/apexpos/ \
  --namespace apexpos \
  --create-namespace
```

### Customize values
You can override configurations dynamically. For instance, to enable the Ingress controller routing:
```bash
helm upgrade apexpos-prod helm/apexpos/ --set ingress.enabled=true -n apexpos
```

---

## 🏗️ 3. Infrastructure as Code (Terraform)

The `terraform` directory provisions a professional AWS VPC with public and private subnets, security groups, and an EC2 instance preconfigured with **k3s (Kubernetes)**, **Docker**, and **Helm** via user-data scripting.

1. **Configure credentials** on your local machine and initialize:
   ```bash
   cd terraform
   terraform init
   ```
2. **Review proposed resources**:
   ```bash
   terraform plan -var="key_name=your-ssh-key"
   ```
3. **Provision resources**:
   ```bash
   terraform apply -var="key_name=your-ssh-key" --auto-approve
   ```
4. **Retrieve cluster configuration**:
   ```bash
   # Run output helper command to copy Kubeconfig locally
   ssh -i your-ssh-key.pem ubuntu@<INSTANCE_IP> 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed 's/127.0.0.1/<INSTANCE_IP>/g' > ./k3s-kubeconfig
   export KUBECONFIG=$(pwd)/k3s-kubeconfig
   ```

---

## 🔄 4. GitOps Delivery with Argo CD

Continuous deployment (CD) is handled using **Argo CD** to sync manifests directly from this GitHub repository.

1. **Deploy Argo CD** to your cluster:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
2. **Apply the GitOps application controller**:
   ```bash
   kubectl apply -f k8s/argocd-app.yml
   ```
   Argo CD will automatically sync configurations and deploy the manifests located in the `k8s/` folder, ensuring the running system matches git commits with zero manual intervention.

---

## 🧪 5. Automated CI/CD Validation Pipeline

Any push or pull request to the `main` or `dev` branch triggers the GitHub Actions pipeline (`validate.yml`):
- **Linting YAML configurations** using `yamllint`.
- **Validating Helm Chart structure** using `helm lint`.
- **Inspecting Dockerfiles** for security breaches and package optimization using `hadolint`.
This ensures no broken configurations or insecure Docker configurations are merged into the repository.
