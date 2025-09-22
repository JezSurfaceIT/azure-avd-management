#!/bin/bash

# Script to view Oversight Next.js logs without killing existing connections

echo "Viewing Oversight Next.js logs on remote Azure VM..."
echo "NOTE: This uses a different port (2224) to avoid conflicts"

# Configuration
BASTION_NAME="secure-bastion"
RESOURCE_GROUP="rg-secure-devops-20250119101101"
SUBSCRIPTION_ID="80265df9-bba2-4ad2-88af-e002fd2ca230"
VM_NAME="vm-dev-uksouth"
USERNAME="azureuser"
SSH_KEY="~/.ssh/azure_vm_key"
LOCAL_PORT="2224"  # Different port to avoid conflicts!

# Full resource ID for the VM
VM_RESOURCE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Compute/virtualMachines/${VM_NAME}"

# Create Bastion tunnel on different port
echo "Creating Bastion SSH tunnel on port ${LOCAL_PORT}..."
az network bastion tunnel \
    --name "${BASTION_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --target-resource-id "${VM_RESOURCE_ID}" \
    --resource-port 22 \
    --port ${LOCAL_PORT} &

# Wait for tunnel to establish
echo "Waiting for tunnel to establish..."
sleep 5

# Check if tunnel is ready
for i in {1..10}; do
    if nc -zv localhost ${LOCAL_PORT} 2>/dev/null; then
        echo "Tunnel established successfully!"
        break
    fi
    echo "Waiting for tunnel... (attempt $i/10)"
    sleep 2
done

# View the dev-server.log file
echo "Viewing Oversight Next.js logs..."
echo "Press Ctrl+C to stop"
echo ""

ssh -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -i ${SSH_KEY} \
    -p ${LOCAL_PORT} \
    ${USERNAME}@localhost \
    "cd /home/azureuser/projects/Oversight-MVP && tail -f dev-server.log"