#!/bin/bash
# ============================================================
#  ApexPOS - EC2 MongoDB Diagnostic & Fix Script
#  EC2 IP: 3.110.182.170
#  Error: Operation 'staffs.find()' buffering timed out
# ============================================================

SSH_KEY="/home/ghost69/projects/Projects/Apex Pos/devops-repo/terraform/aws-cloud-production/apex-pos.pem"
EC2_IP="3.110.182.170"
SSH="ssh -i \"$SSH_KEY\" -o StrictHostKeyChecking=no ubuntu@$EC2_IP"

echo "========================================================"
echo "  ApexPOS EC2 Database Diagnostic"
echo "  Target: ubuntu@${EC2_IP}"
echo "========================================================"
echo ""

echo ">>> [1/5] Checking all pod statuses in apexpos namespace..."
eval $SSH "sudo kubectl get pods -n apexpos -o wide"
echo ""

echo ">>> [2/5] Checking PVC (Persistent Volume Claim) status..."
eval $SSH "sudo kubectl get pvc -n apexpos"
echo ""

echo ">>> [3/5] Last 30 lines of DATABASE pod logs..."
eval $SSH "sudo kubectl logs -n apexpos -l app=apexpos-database --tail=30 2>&1"
echo ""

echo ">>> [4/5] Last 30 lines of BACKEND pod logs..."
eval $SSH "sudo kubectl logs -n apexpos -l app=apexpos-backend --tail=30 2>&1"
echo ""

echo ">>> [5/5] Recent events in apexpos namespace..."
eval $SSH "sudo kubectl get events -n apexpos --sort-by='.lastTimestamp' 2>&1 | tail -20"
echo ""

echo ">>> [BONUS] Checking node memory usage..."
eval $SSH "free -h && echo '' && sudo kubectl top nodes 2>/dev/null || true"
echo ""

echo "========================================================"
echo "  Diagnostic Complete."
echo ""
echo "  IF database pod is NOT 'Running', run the FIX script:"
echo "  bash fix-db.sh"
echo "========================================================"
