#!/bin/bash

# 🎨 Terminal Styling Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ℹ️ Header Print
print_header() {
  echo -e "\n${BOLD}${CYAN}=====================================================================${NC}"
  echo -e "${BOLD}${MAGENTA}   🚀 ApexPOS Enterprise DevOps Local Platform Orchestration Hub     ${NC}"
  echo -e "${BOLD}${CYAN}=====================================================================${NC}"
}

# ℹ️ Logger Helpers
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS] [✔]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARNING] [!]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR] [✘]${NC} $1"
}

# 📋 Usage Instructions
usage() {
  echo -e "Usage: $0 [start|stop|status|restart]"
  echo -e "  ${BOLD}start${NC}   : Spin up Minikube, enable Ingress, run local Terraform, and boot Jenkins/SonarQube."
  echo -e "  ${BOLD}stop${NC}    : Tear down local Kubernetes resources, Docker containers, and halt Minikube."
  echo -e "  ${BOLD}status${NC}  : Check the health of K8s namespaces, Docker-compose infra, and list endpoints."
  echo -e "  ${BOLD}restart${NC} : Restart the local environment."
  exit 1
}

# 🔍 Check Dependencies
check_dependencies() {
  log_info "Verifying prerequisites..."
  
  dependencies=("docker" "minikube" "kubectl" "terraform")
  for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      log_error "Missing required dependency: $dep"
      if [ "$dep" == "minikube" ]; then
        echo "Please install Minikube: https://minikube.sigs.k8s.io/docs/start/"
      elif [ "$dep" == "terraform" ]; then
        echo "Please install Terraform: https://developer.hashicorp.com/terraform/downloads"
      fi
      exit 1
    fi
  done
  log_success "All dependency checks passed."
}

# 🚀 Start Local Infrastructure
start_infra() {
  print_header
  check_dependencies

  # 1. Start Minikube
  log_info "Initializing local Kubernetes cluster (Minikube)..."
  if minikube status | grep -q "Running"; then
    log_success "Minikube cluster is already running."
  else
    log_info "Starting Minikube (Allocating 4 vCPUs, 8GB RAM)..."
    # We configure an insecure registry to trust local docker registry running on host (localhost:5000 or host.minikube.internal:5000)
    minikube start \
      --cpus=4 \
      --memory=8192 \
      --insecure-registry="host.minikube.internal:5000"
      
    if [ $? -ne 0 ]; then
      log_error "Failed to start Minikube. Verify resource limits or drivers."
      exit 1
    fi
  fi

  # 2. Enable Ingress Addon
  log_info "Enabling Nginx Ingress Controller inside Minikube..."
  minikube addons enable ingress
  
  # 3. Boot Jenkins & SonarQube via Docker Compose
  log_info "Launching Local Jenkins, SonarQube & Docker Registry sandbox..."
  docker compose -f docker-compose-infra.yml up -d
  if [ $? -ne 0 ]; then
    log_error "Docker Compose infra startup failed."
    exit 1
  fi
  log_success "CI/CD sandbox stack is running in Docker."

  # 4. Bootstrap Kubernetes configurations via Terraform
  log_info "Running local Terraform bootstrap scripts..."
  cd terraform/local-minikube
  terraform init
  terraform apply -auto-approve
  
  if [ $? -ne 0 ]; then
    log_error "Terraform provisioning failed."
    cd ../..
    exit 1
  fi
  cd ../..
  log_success "Terraform successfully provisioned Kubernetes namespaces, secrets, ArgoCD, and Prometheus/Grafana."

  # 5. Output local domains helper instructions
  show_status
}

# 🛑 Stop Local Infrastructure
stop_infra() {
  print_header
  log_info "Initiating teardown sequence..."

  # 1. Destroy Terraform provisioned resources
  if [ -d "terraform/local-minikube" ]; then
    log_info "Destroying K8s namespaces and Helm packages via Terraform..."
    cd terraform/local-minikube
    terraform destroy -auto-approve
    cd ../..
    log_success "Terraform cleanup completed."
  fi

  # 2. Stop Docker Compose Stack
  log_info "Stopping Docker Compose Jenkins & SonarQube sandbox..."
  docker compose -f docker-compose-infra.yml down -v
  log_success "Docker infrastructure containers stopped."

  # 3. Halt Minikube
  log_info "Stopping Minikube VM..."
  minikube stop
  log_success "Minikube stopped."
  
  echo -e "\n${BOLD}${GREEN}✔ All local resources cleaned up successfully!${NC}"
}

# 🩺 Show Status & Endpoints
show_status() {
  print_header
  
  log_info "Querying local environments..."
  
  # Get Minikube IP
  MINIKUBE_IP=$(minikube ip 2>/dev/null)
  
  if [ -z "$MINIKUBE_IP" ]; then
    log_warn "Minikube is not running."
    exit 0
  fi
  
  echo -e "\n${BOLD}${CYAN}--- Cluster Node Status ---${NC}"
  echo -e "Minikube IP Address: ${BOLD}${GREEN}${MINIKUBE_IP}${NC}"
  
  echo -e "\n${BOLD}${CYAN}--- Local Docker Compose Infrastructure ---${NC}"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E 'devops-|sonarqube|sonar-db|Names'
  
  echo -e "\n${BOLD}${CYAN}--- Kubernetes Application Pods (Namespace: apexpos) ---${NC}"
  kubectl get pods -n apexpos
  
  echo -e "\n${BOLD}${CYAN}--- Kubernetes Monitoring Pods (Namespace: monitoring) ---${NC}"
  kubectl get pods -n monitoring | head -n 8
  
  echo -e "\n${BOLD}${CYAN}--- DevOps Platform Endpoints ---${NC}"
  echo -e "👉 ${BOLD}ApexPOS App${NC}       : http://apexpos.local"
  echo -e "👉 ${BOLD}ArgoCD Console${NC}   : http://argocd.local"
  echo -e "👉 ${BOLD}Grafana Dashboard${NC}: http://grafana.local   (Credentials: admin / admin)"
  echo -e "👉 ${BOLD}Jenkins Server${NC}   : http://localhost:8085  (Bypassed Login for Sandbox)"
  echo -e "👉 ${BOLD}SonarQube Dashboard${NC}: http://localhost:9000 (Credentials: admin / SonarQubeAdmin123_)"
  
  echo -e "\n${BOLD}${YELLOW}⚠️  Action Required: Update your /etc/hosts file${NC}"
  echo -e "To resolve the local domains, add the following line to your ${BOLD}/etc/hosts${NC}:"
  echo -e "  ${BOLD}${GREEN}${MINIKUBE_IP} apexpos.local argocd.local grafana.local${NC}"
  echo ""
}

# 🚀 Orchestrator Choice
case "$1" in
  start)
    start_infra
    ;;
  stop)
    stop_infra
    ;;
  status)
    show_status
    ;;
  restart)
    stop_infra
    start_infra
    ;;
  *)
    usage
    ;;
esac
