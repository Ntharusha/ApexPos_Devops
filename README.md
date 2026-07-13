# ☁️ ApexPOS DevOps Infrastructure & Orchestration Hub

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple.svg?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.28+-blue.svg?logo=kubernetes)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-v3-blue.svg?logo=helm)](https://helm.sh/)
[![AWS](https://img.shields.io/badge/AWS-EC2%20%26%20VPC-orange.svg?logo=amazonwebservices)](https://aws.amazon.com/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-red.svg?logo=jenkins)](https://www.jenkins.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-orange.svg?logo=argocd)](https://argo-cd.readthedocs.io/)
[![Docker](https://img.shields.io/badge/Docker-Containers-blue.svg?logo=docker)](https://www.docker.com/)

This repository serves as the central **Infrastructure as Code (IaC)**, **GitOps**, and **Orchestration Hub** for the ApexPOS software suite. It contains production Terraform configurations, Kubernetes raw manifests, Helm Charts, and automated delivery pipelines.

---

## 🏛️ Overall DevOps & Network Architecture

The deployment is hosted on **AWS EC2** running a single-node **K3s Kubernetes cluster** inside a secure custom VPC network.

```mermaid
graph TD
    %% Define Styles
    classDef aws fill:#ff9900,stroke:#d68100,stroke-width:2px,color:#000;
    classDef k8s fill:#326ce5,stroke:#204fa8,stroke-width:2px,color:#fff;
    classDef tools fill:#d0021b,stroke:#a00010,stroke-width:2px,color:#fff;
    classDef network fill:#7ed321,stroke:#5fa018,stroke-width:2px,color:#000;

    %% Client Layer
    Client[📱 Web Client / User] -->|HTTP / DNS: *.nip.io| IGW[Internet Gateway]:::network
    
    subgraph AWS_VPC ["AWS Custom VPC (10.0.0.0/16)"]
        direction TB
        subgraph PublicSubnet ["Public Subnet (10.0.1.0/24)"]
            direction TB
            IGW -->|Route Table| EC2[🚀 EC2 Instance: t3.small]:::aws
        end
    end

    %% EC2 Core Engine
    subgraph Host_System ["EC2 VM (Ubuntu OS)"]
        direction TB
        DockerD[🐳 Host Docker Daemon]:::tools
        K3s[☸️ K3s Single-Node Cluster]:::k8s
        
        %% Jenkins on Host
        subgraph CD_Engine ["CI/CD Pipeline Engine"]
            Jenkins[⚙️ Jenkins Docker Container: Port 8085]:::tools
            Jenkins -->|Mounts| DockerD
            Jenkins -->|Mounts| KubeConfig[kubeconfig]:::k8s
        end
    end

    %% K8s Pods
    subgraph Namespace_ApexPOS ["Kubernetes Namespace: apexpos"]
        direction TB
        Ingress[🕸️ Nginx Ingress Controller]:::k8s
        FE[💻 Frontend Pods]:::k8s
        BE[🚀 Backend Pods]:::k8s
        DB[(🍃 MongoDB StatefulSet)]:::k8s
        PVC[(💾 AWS EBS Persistent Volume)]:::aws
    end

    %% Routing inside K3s
    EC2 -->|Exposes| Ingress
    Ingress -->|Path /| FE
    Ingress -->|Path /api| BE
    BE -->|Internal DNS| DB
    DB <--->|Mounts| PVC
    
    %% CD Updates
    Jenkins -.->|Deploy Rollout| BE
    Jenkins -.->|Deploy Rollout| FE
```

---

## 🚦 Traffic & Ingress Routing Flow

This diagram illustrates how client requests are routed through the networking stack down to the respective application pods.

```mermaid
sequenceDiagram
    autonumber
    actor User as 📱 Client Web App
    participant IG as 🌐 Ingress Nginx (Port 80)
    participant FESvc as 🔌 Frontend Service
    participant FEPod as 💻 Frontend Pod
    participant BESvc as 🔌 Backend Service
    participant BEPod as 🚀 Backend Pod
    participant DB as 🍃 MongoDB Pod

    User->>IG: Request http://13.235.9.45/ (Home Page)
    IG->>FESvc: Matches rule '/'
    FESvc->>FEPod: Route to active Pod
    FEPod-->>User: Returns React SPA Build

    User->>IG: Request http://13.235.9.45/api/products (API call)
    IG->>BESvc: Matches rule '/api'
    BESvc->>BEPod: Route to Node.js backend
    BEPod->>DB: Fetch products
    DB-->>BEPod: Return MongoDB records
    BEPod-->>User: Returns JSON response
```

---

## 🔄 Dual GitOps & CI/CD Pipeline Flow

Our delivery architecture separates concerns by utilizing **Jenkins** for Continuous Integration (CI) and **ArgoCD** for GitOps Continuous Delivery (CD).

```mermaid
graph LR
    classDef git fill:#f05032,stroke:#333,stroke-width:1px,color:#fff;
    classDef ci fill:#d0021b,stroke:#333,stroke-width:1px,color:#fff;
    classDef gitops fill:#f57c00,stroke:#333,stroke-width:1px,color:#fff;
    classDef k8s fill:#326ce5,stroke:#333,stroke-width:1px,color:#fff;

    Developer[💻 Developer Push]:::git -->|App Code| AppRepo[📁 ApexPOS App Repo]:::git
    Developer -->|Manifests / IaC| DevopsRepo[📁 ApexPOS DevOps Repo]:::git

    subgraph Jenkins_CI ["Jenkins CI Loop"]
        AppRepo -->|WebHook Trigger| Jenkins[⚙️ Jenkins Runner]:::ci
        Jenkins -->|Lint & Test| BuildImage[🐳 Build Docker Image]:::ci
        BuildImage -->|Push| HostDocker[🐳 Host Registry / Cache]:::ci
        HostDocker -->|Trigger Rollout| K3sCluster[☸️ K3s Cluster]:::k8s
    end

    subgraph ArgoCD_GitOps ["ArgoCD GitOps Reconciliation"]
        DevopsRepo -->|WebHook/Poll| Argo[🐙 ArgoCD Controller]:::gitops
        Argo -->|Compares desired state| Sync[🔄 Auto-Sync & Self-Heal]:::gitops
        Sync -->|Reconcile State| K3sCluster:::k8s
    end
```

---

## 📁 Repository Directory Layout

```text
├── helm/
│   └── apexpos/              # Premium Helm chart packaging for ApexPOS
│       ├── templates/        # Kubernetes resource templates (Deployments, Services, Ingress)
│       ├── Chart.yaml        # Chart metadata
│       └── values.yaml       # Global values configurations
├── k8s/                      # Raw Kubernetes manifests (Alternative to Helm)
│   ├── namespace.yml         # Shared Namespace setup
│   ├── backend/              # Deployment, ClusterIP Service, ConfigMap & Secrets
│   ├── database/             # MongoDB Deployment, Service, PVC
│   ├── frontend/             # Nginx reverse proxy configuration & UI Deployment
│   ├── ingress.yml           # Traffic routing rule manifest
│   └── argocd-app.yml        # GitOps Application definition
└── terraform/                # Infrastructure as Code (IaC)
    └── aws-cloud-production/ # Production environment VPC & Host setup
        ├── providers.tf      # Cloud provider configurations
        ├── variables.tf      # System variables & defaults
        ├── vpc.tf            # Custom VPC, subnets, route tables, & gateway
        ├── security_groups.tf# Firewall rules for HTTP/HTTPS/SSH/Jenkins
        ├── ec2.tf            # EC2 instance bootstrapping (Docker, K3s, Jenkins setups)
        └── outputs.tf        # Access IP addresses & host values
```

---

## 📊 Observability Stack (Prometheus + Grafana)

ApexPOS ships a full monitoring stack using the [`kube-prometheus-stack`](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) Helm chart, optimized for the `t3.small` resource profile.

### Components

| Component | Role | Port |
|---|---|---|
| **Prometheus** | Metrics scraping & storage (7-day retention) | Internal |
| **Grafana** | Visualization dashboards | `NodePort 30300` |
| **Node Exporter** | Host-level CPU / RAM / Disk metrics | DaemonSet |
| **Kube State Metrics** | Kubernetes object state metrics | ClusterIP |

### Custom ApexPOS Dashboard

A pre-built Grafana dashboard (`apexpos-overview`) is auto-loaded via a ConfigMap and displays:

- 🖥️ **Node CPU, Memory & Disk usage** (real-time)
- 🚀 **Pod CPU & Memory** for the `apexpos` namespace
- 🟢 **Running pod count** health indicator
- 🍃 **MongoDB pod restart counter** for stability monitoring

### Install Monitoring Stack

```bash
# Run from devops-repo root (requires kubectl + helm configured)
bash monitoring/install-monitoring.sh
```

### Access Grafana

```
URL      : http://<EC2_PUBLIC_IP>:30300
Username : admin
Password : ApexPOS@2026
```

> **Note:** Port `30300` is pre-configured in the Terraform security group.  
> For local access without a public IP: `kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80`

---

## 🛠️ Infrastructure Provisioning (Terraform)

The Infrastructure as Code (IaC) logic creates a customized secure virtual networking stack on AWS to host K3s.

### Steps to Provision
Ensure you have the AWS CLI configured locally:
```bash
cd terraform/aws-cloud-production
terraform init
terraform plan
terraform apply -auto-approve
```

---

## ⚙️ CI/CD Jenkins Pipeline Configuration

Our CI/CD engine is hosted inside a Docker container with mounted host sockets for fast, zero-cost builds.

### Pipeline Lifecycle Steps
1. **Lint and Validate:** Verifies React and Node syntax before compiling.
2. **Build and Tag:** Compiles optimized client and server Docker containers.
3. **Local Socket Mounting:** Accesses host engine via `/var/run/docker.sock` to prevent nested container overhead.
4. **K3s Deploy:** Triggers zero-downtime rolling updates in the cluster.

---

## 🔒 Crucial DevOps Fixes & Enhancements

### 1. Database Rolling Update Lock (Fixed)
* **Problem:** Standard rolling updates (`RollingUpdate` strategy) start a new pod before killing the old one. However, the database uses a **ReadWriteOnce (RWO)** Persistent Volume Claim. Since two pods cannot mount the volume simultaneously, the new database pod crashes (`CrashLoopBackOff`), causing a deployment deadlock.
* **Fix:** Configured the database deployment strategy to **`Recreate`**. This terminates the existing database pod and releases the volume lock before launching the new replica, guaranteeing smooth deployments.

### 2. Node Memory Optimizations (Fixed)
* **Problem:** A `t3.small` AWS instance has only 2GB RAM. Running MongoDB with default settings will quickly cause Out-Of-Memory (OOM) host failures.
* **Fix:** Limited the MongoDB WiredTiger cache size to **256MB** (`--wiredTigerCacheSizeGB 0.25`) and set CPU/Memory resource constraints inside Kubernetes manifests.

---

## 📝 Common Kubernetes Operations Cheat Sheet

### 1. Check Resources
```bash
sudo kubectl get all -n apexpos
sudo kubectl get pv,pvc -n apexpos
```

### 2. View Real-Time Logs
```bash
sudo kubectl logs -n apexpos deployment/apexpos-backend --tail=100 -f
sudo kubectl logs -n apexpos deployment/apexpos-frontend --tail=100 -f
```

### 3. Database Seeding via Pod Tunnel
```bash
# Seed default admin login credentials
ssh -i "apex-pos.pem" ubuntu@13.235.9.45 "sudo kubectl exec -i -n apexpos deployment/apexpos-backend -- node" < "../ApexPOS/server/seedAdmin.js"

# Seed sample product catalogue
ssh -i "apex-pos.pem" ubuntu@13.235.9.45 "sudo kubectl exec -i -n apexpos deployment/apexpos-backend -- node" < "../ApexPOS/server/seedProducts.js"
```
