variable "project_name" {
  type        = string
  description = "Project name"
  default     = "apexpos"
}

variable "app_namespace" {
  type        = string
  description = "Target namespace for the ApexPOS application"
  default     = "apexpos"
}

variable "monitoring_namespace" {
  type        = string
  description = "Target namespace for Prometheus and Grafana monitoring"
  default     = "monitoring"
}

variable "argocd_namespace" {
  type        = string
  description = "Target namespace for ArgoCD GitOps operator"
  default     = "argocd"
}
