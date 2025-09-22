#!/bin/bash

# Azure Dev VM SSH Connection Script
# This script establishes a Bastion tunnel and connects to the Azure dev VM

echo "Setting up SSH connection to Azure Dev VM..."

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
echo "Checking for existing tunnels..."
if lsof -Pi :${LOCAL_PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "Killing existing process on port ${LOCAL_PORT}..."
    kill $(lsof -Pi :${LOCAL_PORT} -sTCP:LISTEN -t) 2>/dev/null || true
    sleep 2
fi

# Create Bastion tunnel
echo "Creating Bastion SSH tunnel..."
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

# Connect via SSH
echo "Connecting to Azure Dev VM..."
ssh -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -i ${SSH_KEY} \
    -p ${LOCAL_PORT} \
    ${USERNAME}@localhost