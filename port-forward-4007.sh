#!/bin/bash

# Port Forwarding Script for Azure Dev VM
# Forwards remote port 4007 to local port 4007

echo "Setting up port forwarding for port 4007..."

# Configuration
BASTION_NAME="secure-bastion"
RESOURCE_GROUP="rg-secure-devops-20250119101101"
SUBSCRIPTION_ID="80265df9-bba2-4ad2-88af-e002fd2ca230"
VM_NAME="vm-dev-uksouth"
USERNAME="azureuser"
SSH_KEY="~/.ssh/azure_vm_key"
REMOTE_PORT="4007"
LOCAL_PORT="4007"

# Full resource ID for the VM
VM_RESOURCE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Compute/virtualMachines/${VM_NAME}"

# Kill any existing process on the local port
echo "Checking for existing processes on port ${LOCAL_PORT}..."
if lsof -Pi :${LOCAL_PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "Killing existing process on port ${LOCAL_PORT}..."
    kill $(lsof -Pi :${LOCAL_PORT} -sTCP:LISTEN -t) 2>/dev/null || true
    sleep 2
fi

# Create Bastion tunnel with port forwarding
echo "Creating Bastion tunnel with port forwarding..."
echo "Remote port ${REMOTE_PORT} will be forwarded to local port ${LOCAL_PORT}"
echo ""
echo "Access your application at: http://localhost:${LOCAL_PORT}"
echo "Press Ctrl+C to stop the tunnel"
echo ""

# Use az network bastion tunnel for port forwarding
az network bastion tunnel \
    --name "${BASTION_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --target-resource-id "${VM_RESOURCE_ID}" \
    --resource-port ${REMOTE_PORT} \
    --port ${LOCAL_PORT}