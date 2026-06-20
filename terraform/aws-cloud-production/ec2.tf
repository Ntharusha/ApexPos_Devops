# Lookup latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Provision Single Node k3s Instance in Public Subnet (for portfolio simplicity and cost control)
resource "aws_instance" "k8s_node" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30 # AWS Free Tier allows up to 30GB EBS
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # 1. Update and install prerequisite packages
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common git jq

              # 2. Install Docker
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              chmod a+r /etc/apt/keyrings/docker.asc
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io

              # Add ubuntu user to docker group
              usermod -aG docker ubuntu

              # 3. Install k3s (Lightweight Kubernetes)
              # Disable default servicelb and traefik to showcase manual Ingress/Service configuration
              curl -sfL https://get.k3s.io | sh -s - --disable servicelb --disable traefik

              # Wait for node configuration
              sleep 15

              # Set kubeconfig permissions for ubuntu user
              mkdir -p /home/ubuntu/.kube
              cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
              chown -R ubuntu:ubuntu /home/ubuntu/.kube
              chmod 600 /home/ubuntu/.kube/config

              # 4. Install Helm
              curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

              # 5. Pre-create the apexpos namespace
              /usr/local/bin/kubectl create namespace apexpos || true

              echo "Bootstrap completed successfully!"
              EOF

  tags = {
    Name        = "${var.project_name}-k8s-node"
    Environment = var.environment
  }
}
