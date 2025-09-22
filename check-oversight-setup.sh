#!/bin/bash

# Script to check how Oversight app is running on remote Azure VM

echo "Checking Oversight app setup on Azure Dev VM..."

# Configuration
BASTION_NAME="secure-bastion"
RESOURCE_GROUP="rg-secure-devops-20250119101101"
SUBSCRIPTION_ID="80265df9-bba2-4ad2-88af-e002fd2ca230"
VM_NAME="vm-dev-uksouth"
USERNAME="azureuser"
SSH_KEY="~/.ssh/azure_vm_key"
LOCAL_PORT="2223"

# Full resource ID for the VM
VM_RESOURCE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Compute/virtualMachines/${VM_NAME}"

# Kill any existing tunnel on port 2223
echo "Setting up connection..."
if lsof -Pi :${LOCAL_PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
    kill $(lsof -Pi :${LOCAL_PORT} -sTCP:LISTEN -t) 2>/dev/null || true
    sleep 2
fi

# Create Bastion tunnel
az network bastion tunnel \
    --name "${BASTION_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --target-resource-id "${VM_RESOURCE_ID}" \
    --resource-port 22 \
    --port ${LOCAL_PORT} &

# Wait for tunnel
sleep 5
for i in {1..10}; do
    if nc -zv localhost ${LOCAL_PORT} 2>/dev/null; then
        break
    fi
    sleep 2
done

# Check various ways the app might be running
ssh -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -i ${SSH_KEY} \
    -p ${LOCAL_PORT} \
    ${USERNAME}@localhost << 'EOF'
echo "=== Checking for Node.js processes ==="
ps aux | grep -E "node|npm" | grep -v grep

echo ""
echo "=== Checking for Oversight processes ==="
ps aux | grep -i oversight | grep -v grep

echo ""
echo "=== Checking systemd services ==="
systemctl list-units --type=service --state=running | grep -i oversight || echo "No Oversight systemd service found"

echo ""
echo "=== Checking Docker containers ==="
docker ps 2>/dev/null | grep -i oversight || echo "No Docker containers or Docker not installed"

echo ""
echo "=== Checking common app directories ==="
ls -la /home/azureuser/ | grep -i oversight || true
ls -la /opt/ | grep -i oversight || true
ls -la /var/www/ | grep -i oversight || true

echo ""
echo "=== Checking for running web servers on port 4007 ==="
sudo netstat -tlnp | grep :4007 || echo "No process listening on port 4007"

echo ""
echo "=== Recent system logs mentioning Oversight ==="
sudo journalctl -n 50 | grep -i oversight || echo "No recent logs found"
EOF