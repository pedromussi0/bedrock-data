set -e

# --- Configuration ---
RESOURCE_GROUP_NAME="rg-bedrock"
VM_NAME="vm-bedrock-host"

echo "--- Stopping Billable Services for Project Bedrock ---"

# --- 1. Deallocate the Virtual Machine ---
echo -e "\n--- Deallocating Virtual Machine '$VM_NAME' ---"
echo "This will stop compute charges for the VM."

# The 'deallocate' command stops the VM and releases the hardware.
az vm deallocate \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$VM_NAME" \
    --output table

echo "VM '$VM_NAME' has been successfully deallocated."

# --- 2. Reminders for Other Services ---
echo -e "\n--- Cost-Saving Reminders ---"
echo "✅ VM Deallocated: Compute charges have stopped."
echo "🔵 Databricks: To stop Databricks costs, ensure your compute clusters are TERMINATED from within the Databricks workspace UI. Use the 'Auto-termination' setting on your clusters to do this automatically."
echo "📦 Storage Account: This service cannot be stopped, but costs for development-scale data are typically very low."
echo -e "\n--- Shutdown Checklist Complete ---"