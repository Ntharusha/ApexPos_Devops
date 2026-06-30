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

# Import existing SSH key pair into the target region automatically
resource "aws_key_pair" "apex_pos" {
  key_name   = var.key_name
  public_key = file("${path.module}/apex-pos-public.pub")
}

# Provision Single Node k3s Instance in Public Subnet (for portfolio simplicity and cost control)
resource "aws_instance" "k8s_node" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = aws_key_pair.apex_pos.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30 # AWS Free Tier allows up to 30GB EBS
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<EOF
#!/bin/bash
set -e

# Configure Swap Space (Crucial for t3.small with 2GB RAM to avoid Out-Of-Memory issues)
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 1. Update and install prerequisite packages
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common git jq

# 2. Install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu jammy stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# 3. Install k3s (Lightweight Kubernetes) with Docker container runtime
# Fetch public IP dynamically and add it to TLS SAN to avoid certificate validation issues
PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s ifconfig.me)
curl -sfL https://get.k3s.io | sh -s - --docker --disable servicelb --disable traefik --tls-san $PUBLIC_IP

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

# 6. Build and start custom Jenkins container
mkdir -p /opt/jenkins
cat <<'JENKINS_DOCKER' > /opt/jenkins/Dockerfile
FROM jenkins/jenkins:lts
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends docker.io curl ca-certificates nodejs npm && \
    rm -rf /var/lib/apt/lists/*
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl
USER jenkins
RUN jenkins-plugin-cli --plugins git workflow-aggregator pipeline-stage-view
JENKINS_DOCKER

docker build -t custom-jenkins /opt/jenkins

docker run -d --name devops-jenkins \
  --restart always \
  --network host \
  -u root \
  -v /var/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc/rancher/k3s/k3s.yaml:/root/.kube/config \
  -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
  custom-jenkins --httpPort=8085

echo "Bootstrap completed successfully!"
EOF

  tags = {
    Name        = "${var.project_name}-k8s-node"
    Environment = var.environment
  }
}
