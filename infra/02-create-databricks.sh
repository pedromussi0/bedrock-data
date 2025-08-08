set -e

# --- Configuration ---
RESOURCE_GROUP_NAME="rg-bedrock"
WORKSPACE_NAME="dbr-bedrock-workspace"
LOCATION="East US"
SKU="premium" # 'premium' is required for key CI/CD and security features.

echo "--- Attempting to create Azure Databricks Workspace '$WORKSPACE_NAME' ---"
echo "IMPORTANT: This script assumes you have already manually checked that the workspace does not exist."
echo "The creation process can take several minutes. Please be patient."

# Create the Azure Databricks workspace.
# CORRECTED: Variables are now quoted to handle spaces correctly.
az databricks workspace create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$WORKSPACE_NAME" \
    --location "$LOCATION" \
    --sku "$SKU" \
    --output table

echo "Databricks workspace '$WORKSPACE_NAME' created successfully."

# --- Output Workspace URL for easy access ---
echo -e "\n--- Provisioning Complete. Retrieving Workspace URL ---"
WORKSPACE_URL=$(az databricks workspace show --resource-group "$RESOURCE_GROUP_NAME" --name "$WORKSPACE_NAME" --query "workspaceUrl" -o tsv)

echo "--------------------------------------------------"
echo "Databricks Workspace URL:"
echo "https://$WORKSPACE_URL"
echo "--------------------------------------------------"