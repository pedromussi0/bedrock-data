# This script starts the main Virtual Machine for Project Bedrock.

set -e

# --- Configuration ---
RESOURCE_GROUP_NAME="rg-bedrock"
VM_NAME="vm-bedrock-host"

echo "--- Starting Virtual Machine '$VM_NAME' ---"

# The 'start' command re-provisions the VM on Azure hardware.
az vm start \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$VM_NAME" \
    --output table

echo "VM '$VM_NAME' is starting."

# Retrieve and display the public IP address, as it may have changed.
echo -e "\n--- Retrieving Public IP Address ---"
PUBLIC_IP_ADDRESS=$(az vm show \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$VM_NAME" \
    --show-details \
    --query "publicIps" \
    --output tsv)

echo "--------------------------------------------------"
echo "VM Public IP Address: $PUBLIC_IP_ADDRESS"
echo "You can now connect using: ssh azureuser@$PUBLIC_IP_ADDRESS"
echo "--------------------------------------------------"