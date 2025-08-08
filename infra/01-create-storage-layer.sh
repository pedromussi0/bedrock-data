set -e

# --- Configuration ---
# The location can impact cost, but 'East US' is generally one of the most economical regions.
RESOURCE_GROUP_NAME="rg-bedrock"
LOCATION="East US"
STORAGE_ACCOUNT_PREFIX="bedrockstor"
CONTAINER_NAME="raw-data"

# COST-SAVING CHOICE: Standard_LRS (Locally-Redundant Storage) is the lowest-cost SKU.
# It is ideal for development, testing, and non-critical data scenarios.
STORAGE_SKU="Standard_LRS"

echo "IMPORTANT: Make sure you have selected the correct subscription (e.g., 'Azure for Students')"
echo "using 'az account set --subscription \"Your Subscription Name\"' before running this."
echo ""

# --- 1. Resource Group Creation (Idempotent) ---
echo "--- Ensuring Resource Group '$RESOURCE_GROUP_NAME' exists in '$LOCATION' ---"
if [ $(az group exists --name $RESOURCE_GROUP_NAME) = false ]; then
    echo "Resource Group '$RESOURCE_GROUP_NAME' not found. Creating..."
    az group create --name $RESOURCE_GROUP_NAME --location "$LOCATION" --output none
    echo "Resource Group '$RESOURCE_GROUP_NAME' created successfully."
else
    echo "Resource Group '$RESOURCE_GROUP_NAME' already exists."
fi

# --- 2. Storage Account Creation (Idempotent) ---
echo -e "\n--- Ensuring Storage Account with prefix '$STORAGE_ACCOUNT_PREFIX' exists ---"
EXISTING_STORAGE_ACCOUNT=$(az storage account list --resource-group $RESOURCE_GROUP_NAME --query "[?starts_with(name,'$STORAGE_ACCOUNT_PREFIX')].name" -o tsv)

if [ -z "$EXISTING_STORAGE_ACCOUNT" ]; then
    UNIQUE_SUFFIX=$(openssl rand -hex 6)
    STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_PREFIX}${UNIQUE_SUFFIX}"
    
    echo "No storage account with prefix '$STORAGE_ACCOUNT_PREFIX' found. Creating new account '$STORAGE_ACCOUNT_NAME'..."
    # Globally check if the generated name is available to avoid conflicts.
    while [ $(az storage account check-name --name $STORAGE_ACCOUNT_NAME --query 'nameAvailable' -o tsv) = "false" ]; do
        echo "Storage account name '$STORAGE_ACCOUNT_NAME' is already taken. Generating a new one."
        UNIQUE_SUFFIX=$(openssl rand -hex 6)
        STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_PREFIX}${UNIQUE_SUFFIX}"
    done
    az storage account create \
        --name $STORAGE_ACCOUNT_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --location "$LOCATION" \
        --sku $STORAGE_SKU \
        --kind StorageV2 \
        --output none
    echo "Storage Account '$STORAGE_ACCOUNT_NAME' created successfully with the cost-effective '$STORAGE_SKU' SKU."
else
    STORAGE_ACCOUNT_NAME=$EXISTING_STORAGE_ACCOUNT
    echo "Using existing storage account: '$STORAGE_ACCOUNT_NAME'"
fi

# --- 3. Blob Container Creation (Idempotent) ---
echo -e "\n--- Ensuring Blob Container '$CONTAINER_NAME' exists ---"
# First, get the connection string which is a reliable way to authenticate container operations.
CONNECTION_STRING=$(az storage account show-connection-string --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME -o tsv)

# We redirect output to /dev/null to keep the script log clean.
if az storage container exists --name $CONTAINER_NAME --connection-string "$CONNECTION_STRING" >/dev/null 2>&1; then
    # If the command succeeds (exit code 0), the container already exists.
    echo "Container '$CONTAINER_NAME' already exists."
else
    # If the command fails (non-zero exit code), the container does not exist, so we create it.
    echo "Container '$CONTAINER_NAME' not found. Creating..."
    az storage container create \
        --name $CONTAINER_NAME \
        --connection-string "$CONNECTION_STRING" \
        --output none
    echo "Container '$CONTAINER_NAME' created successfully."
fi

# --- 4. Output Final Connection String ---
echo -e "\n--- Provisioning Complete. Retrieving Final Outputs ---"
echo "--------------------------------------------------"
echo "Storage Account Connection String:"
echo $CONNECTION_STRING
echo "--------------------------------------------------"