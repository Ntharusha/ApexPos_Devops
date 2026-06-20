# 🎓 ApexPOS DevOps Interview Preparation Guide

This guide is designed to help you explain the **ApexPOS SaaS Infrastructure** project in interviews. It covers the elevator pitch, architecture highlights, expected questions, exceptional answers, troubleshooting scenarios, and key terminologies.

---

## 🚀 1. The 60-Second Elevator Pitch (How to Introduce the Project)

When the interviewer says: *"Tell me about a project you've worked on recently."*

> **"Recently, I designed and built a production-grade DevOps sandbox for ApexPOS, an enterprise SaaS Point of Sale platform. The objective was to create a zero-cloud-cost production-replica environment running entirely on local Kubernetes (Minikube).**
>
> **Instead of using simple manual scripts, I wrote Terraform configuration files using Kubernetes and Helm providers to bootstrap the cluster. This automatically provisions namespaces, configures secrets, and deploys Argo CD for GitOps delivery, alongside a Prometheus and Grafana stack for full cluster observability.**
> 
> **For traffic routing, I enabled an Nginx Ingress Controller mapping custom local domains like 'apexpos.local', 'argocd.local', and 'grafana.local' directly to my Minikube cluster. In addition, I created a local CI/CD sandbox using Docker Compose to run Jenkins and SonarQube for static analysis, and wrote an automated bash orchestration script to manage the entire platform lifecycle. Finally, I maintained a separate Terraform configuration repository representing our AWS production network (VPC, subnets, NAT Gateways, EC2 hosting K3s) to showcase my cloud engineering capabilities."**

---

## 🏛️ 2. Architectural Highlights & "Why" (Design Decisions)

Use these explanations to show that you don't just write code, but you understand **architectural trade-offs** and **operational efficiency**.

| Technology | What it does | Why we used it (The "Exceptional" Reason) |
| :--- | :--- | :--- |
| **Local-First Sandbox** | Runs the entire K8s stack (ArgoCD, Prometheus, Grafana, App) on Minikube. | **Zero Cloud Costs / High Velocity**: Allows testing complex integrations, rollouts, and dashboards locally without accumulating AWS bills or hitting credit limits. |
| **Local Terraform** | Provisions namespaces, secrets, and Helm releases (ArgoCD, Prometheus). | **IaC for K8s Management**: Eliminates manual `helm install` and `kubectl` commands. Declaring Helm charts in Terraform ensures cluster resources are version-controlled and reproducible. |
| **Argo CD (GitOps)** | Syncs K8s manifests directly from Git into Minikube. | **Reconciliation & Self-Healing**: Prevents configuration drift. If a pod or service is manually modified inside Minikube, Argo CD detects it and immediately reverts it back to match Git. |
| **Observability Stack** | Scrapes cluster and pod metrics using Prometheus; visualizes them on Grafana. | **Data-Driven Operations**: Rather than guessing, we can track real-time CPU/Memory usage, pod restarts, and ingress traffic patterns on custom dashboards. |
| **Nginx Ingress** | Routes local domains (`apexpos.local`, `grafana.local`, `argocd.local`) to target services. | **Production-Grade DNS/Routing**: Mimics real-world DNS routing locally. Eliminates port-forwarding and shows how production edge routing is configured. |
| **Jenkins & SonarQube** | Runs static analysis (SAST) and builds Docker images locally. | **Pipeline Automation**: Runs code scans, quality gates, and dockerizes the app, pushing to a local registry accessible by Minikube. |
| **AWS Cloud IaC (Ref)** | Contains AWS VPC, subnets, route tables, and EC2 definitions. | **Cloud Design Capabilities**: Demonstrates that we know how to scale this architecture to AWS when budgets permit, utilizing private/public subnet separation. |

---

## ❓ 3. Core Interview Questions & Exceptional Answers

### Q1: Why did you write Terraform code to deploy ArgoCD and Prometheus/Grafana on Minikube instead of just running helm/kubectl commands?
* **Average Answer**: *"Because it is easier to keep everything in one tool."*
* **Exceptional Answer**: 
  > *"Running manual `helm install` commands in a terminal leads to 'snowflake clusters' where the state of the cluster cannot be easily recreated or documented. By using Terraform with the Kubernetes and Helm providers, I treat the cluster bootstrap sequence as Infrastructure as Code. Anyone on the team can run `terraform apply` on a fresh Minikube instance and spin up the exact same namespace boundaries, secrets, Argo CD version, and Prometheus configurations in seconds, ensuring environment consistency."*

### Q2: How did you configure Minikube to pull images from your host's local Docker registry?
* **Average Answer**: *"I used docker images locally."*
* **Exceptional Answer**:
  > *"I deployed a local registry container on port `5000` via Docker Compose. To allow Minikube to pull from it, I booted Minikube with the flag `--insecure-registry="host.minikube.internal:5000"`. Inside my Kubernetes deployment configurations, I set the image path to `host.minikube.internal:5000/apexpos-backend:latest`. This tells the Minikube virtual machine to route image pulls back to the host registry, enabling rapid local build-and-deploy cycles without pushing to public registries like Docker Hub."*

### Q3: Why did you choose to run Prometheus and Grafana locally? Isn't that overkill for a sandbox?
* **Average Answer**: *"I wanted to see how the pods run."*
* **Exceptional Answer**:
  > *"Observability is not an afterthought in DevOps; it must be built into the core design. By deploying the `kube-prometheus-stack` locally, I can verify if our resource requests and limits (`limits.cpu`, `limits.memory`) are set accurately. If the backend suffers from a memory leak, Grafana allows us to see the consumption curve rise until it triggers an OOMKilled event, which we can debug. It prepares the application for production reliability."*

### Q4: How does your Ingress work on localhost without an active domain registrar?
* **Average Answer**: *"I used ingress.yml and minikube ingress addon."*
* **Exceptional Answer**:
  > *"I enabled the Nginx Ingress Controller addon in Minikube, which binds to ports 80/443. To resolve domains like `apexpos.local` and `grafana.local`, I added a static DNS entry mapping the Minikube cluster IP to these domains in my host machine's `/etc/hosts` file. When I navigate to `http://apexpos.local`, the request hits the local Nginx ingress, which matches the Host header and routes the traffic to the unprivileged frontend pod on port 8080."*

---

## 🛠️ 4. Troubleshooting Scenarios (Real-world Debugging)

Hiring managers love to ask: *"Tell me about a time something went wrong and how you debugged it."* 
Use these two scenarios as examples:

### Scenario A: Ingress domains not loading in browser
* **The Problem**: Navigating to `http://apexpos.local` resulted in a "Site not found" error.
* **How you debugged it**:
  > *"I verified that the Nginx Ingress pod was running in the `ingress-nginx` namespace using `kubectl get pods`. Then I ran `minikube ip` and cross-referenced it with my `/etc/hosts` file. I realized that after restarting my computer, Minikube spun up with a different IP address (e.g. `192.168.49.3` instead of `192.168.49.2`). I updated the `/etc/hosts` file with the new IP address, and the ingress started resolving immediately."*

### Scenario B: Jenkins failing to connect to local Kubernetes (Minikube)
* **The Problem**: The deployment stage in the Jenkins pipeline failed with a "connection refused" error when running `kubectl`.
* **How you debugged it**:
  > *"I realized that the Jenkins container was running in an isolated docker network and could not reach the Minikube API server running on the host. To fix this, I set `network_mode: host` in the docker-compose config for Jenkins, and mounted the host's `${HOME}/.kube` and `${HOME}/.minikube` directories into the container. This allowed Jenkins to read the exact same kubeconfig credentials and context that I use on my host machine, resolving the API communication problem."*

---

## 📖 5. DevOps Keywords Cheat Sheet (Speak the Language)

When explaining your work, sprinkle in these industry terms:

* **Snowflake Server/Cluster**: An infrastructure setup that is configured manually, making it unique and impossible to reproduce automatically. (We prevent this with Terraform cluster bootstrapping).
* **GitOps**: An operational framework that takes DevOps best practices (git, CI/CD) and applies them to infrastructure automation (Argo CD is the GitOps tool here).
* **Configuration Drift**: When live cluster configurations drift away from what is declared in Git due to manual intervention. (Argo CD self-healing prevents this).
* **SAST (Static Application Security Testing)**: Analyzing source code or build configuration files for security vulnerabilities without executing the code. (We achieve this using SonarQube and Hadolint).
* **Node Exporter**: A Prometheus agent that gathers hardware and OS-level metrics from Kubernetes nodes to monitor cluster health.
* **Insecure Registry**: A Docker registry that does not use SSL certificates, typically used in development sandboxes to avoid certificate management overhead.

---

## 🇱🇰 6. Quick Translation Guide (Sinhala to English Thoughts)

If you are practicing in your head in Sinhala, here is how you can translate those concepts to wowed English phrases:

| Sinhala Thought | Professional English Translation |
| :--- | :--- |
| *AWS එකට සල්ලි යන නිසා, අපි මුළු prod setup එකම local Minikube එකක හැදුවා.* | *"We constructed a zero-cost local replica of our production cluster using Minikube to emulate cloud workflows."* |
| *මැනුවල් helm install කරන්නේ නැතුව, Terraform වලින් cluster එක bootstrap කලා.* | *"We managed namespaces and Helm releases declaratively via Terraform to guarantee reproducible setups."* |
| *Prometheus / Grafana දාලා, pod එකකට යන cpu/memory එක බලාගන්න පුළුවන්.* | *"We established an observability pipeline utilizing Prometheus and Grafana to monitor resource utilization limits."* |
| *Localhost:5000 එකට image එක push කරලා Minikube එකට auto pull කලා.* | *"We optimized developer velocity by compiling images into a local insecure registry resolved within the cluster."* |

---

> [!TIP]
> **Final Interview Advice:**
> When presenting this project, keep your terminal and Grafana/ArgoCD consoles open on your screen. Highlight the **reasons** behind your design: *"I used Terraform to bootstrap Helm charts locally because it matches the exact workflow real-world teams use to manage complex setups in AWS or GCP."* Recruiters are heavily impressed by interns who focus on **reproducibility and developer velocity**!
