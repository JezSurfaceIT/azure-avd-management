#!/bin/bash

# Script to view Oversight app console output on remote Azure VM

echo "Connecting to Azure Dev VM to view Oversight logs..."

# Configuration
BASTION_NAME="secure-bastion"
RESOURCE_GROUP="rg-secure-devops-20250119101101"
SUBSCRIPTION_ID="80265df9-bba2-4ad2-88af-e002fd2ca230"
VM_NAME="vm-dev-uksouth"
USERNAME="azureuser"
SSH_KEY="~/.ssh/azure_vm_key"

# Full resource ID for the VM
VM_RESOURCE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Compute/virtualMachines/${VM_NAME}"

# Commands to run on the remote machine
REMOTE_COMMANDS='
echo "=== Checking for Oversight processes ==="
ps aux | grep -i oversight | grep -v grep

echo ""
echo "=== Checking PM2 processes ==="
pm2 list

echo ""
echo "=== Viewing PM2 logs for Oversight ==="
pm2 logs oversight --lines 50

echo ""
echo "=== To follow logs in real-time, run: pm2 logs oversight ==="
'

# Connect via Bastion SSH and run commands
az network bastion ssh \
    --name "${BASTION_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --target-resource-id "${VM_RESOURCE_ID}" \
    --auth-type ssh-key \
    --username "${USERNAME}" \
    --ssh-key "${SSH_KEY}" \
    --command "${REMOTE_COMMANDS}"