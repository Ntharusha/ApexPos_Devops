#!/bin/bash
# ============================================================
#  ApexPOS - MongoDB Fix Script (Run after check-db.sh)
#  EC2 IP: 3.110.182.170
# ============================================================

SSH_KEY="/home/ghost69/projects/Projects/Apex Pos/devops-repo/terraform/aws-cloud-production/apex-pos.pem"
EC2_IP="3.110.182.170"
SSH="ssh -i \"$SSH_KEY\" -o StrictHostKeyChecking=no ubuntu@$EC2_IP"

echo "========================================================"
echo "  ApexPOS - Fixing MongoDB on EC2 k3s"
echo "========================================================"

echo ""
echo ">>> Step 1: Restarting database deployment..."
eval $SSH "sudo kubectl rollout restart deployment/apexpos-database -n apexpos"

echo ""
echo ">>> Step 2: Waiting for database to become ready (up to 2 min)..."
eval $SSH "sudo kubectl rollout status deployment/apexpos-database -n apexpos --timeout=120s"

echo ""
echo ">>> Step 3: Restarting backend (to reconnect to fresh MongoDB)..."
eval $SSH "sudo kubectl rollout restart deployment/apexpos-backend -n apexpos"

echo ""
echo ">>> Step 4: Waiting for backend to become ready..."
eval $SSH "sudo kubectl rollout status deployment/apexpos-backend -n apexpos --timeout=120s"

echo ""
echo ">>> Step 5: Final pod status check..."
eval $SSH "sudo kubectl get pods -n apexpos -o wide"

echo ""
echo ">>> Step 6: Checking backend logs for MongoDB connection..."
sleep 5
eval $SSH "sudo kubectl logs -n apexpos -l app=apexpos-backend --tail=20"

echo ""
echo "========================================================"
echo "  Fix attempt complete!"
echo "  Test the API: curl http://${EC2_IP}:30500/"
echo "  Test the app: http://${EC2_IP}:30080"
echo "========================================================"
