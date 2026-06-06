output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.k8s_node.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance hosting k3s"
  value       = aws_instance.k8s_node.public_ip
}

output "ssh_connection_string" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.k8s_node.public_ip}"
}

output "kubeconfig_export_command" {
  description = "Command to retrieve the Kubeconfig from the instance for local management"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.k8s_node.public_ip} 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed 's/127.0.0.1/${aws_instance.k8s_node.public_ip}/g' > ./k3s-kubeconfig"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}
