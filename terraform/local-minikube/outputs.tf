output "argocd_url" {
  description = "ArgoCD Web UI Localhost Endpoint"
  value       = "http://argocd.local"
}

output "grafana_url" {
  description = "Grafana Web UI Monitoring Endpoint"
  value       = "http://grafana.local"
}

output "apexpos_url" {
  description = "ApexPOS Application Localhost Ingress Endpoint"
  value       = "http://apexpos.local"
}

output "etc_hosts_instruction" {
  description = "Instruction to configure local DNS mapping in /etc/hosts"
  value       = "Add the following line to your /etc/hosts file: \n  <MINIKUBE_IP>  apexpos.local argocd.local grafana.local\n(Replace <MINIKUBE_IP> with the output of 'minikube ip')"
}
