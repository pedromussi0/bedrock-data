# This script idempotently creates a cost-effective virtual machine to act as a host
# for Dockerized services like ClickHouse and a future API for Project Bedrock.

set -e

# --- Configuration ---
RESOURCE_GROUP_NAME="rg-bedrock"
LOCATION="East US"
VM_NAME="vm-bedrock-host"
PUBLIC_IP_NAME="pip-bedrock-host"
NSG_NAME="nsg-bedrock-host"
VM_IMAGE="Ubuntu2204"
VM_SIZE="Standard_B1s"
ADMIN_USERNAME="azureuser"

# --- SSH Key Path from Environment Variable ---
if [ -z "$SSH_PUB_KEY_PATH" ]; then
    echo "ERROR: The 'SSH_PUB_KEY_PATH' environment variable is not set."
    exit 1
fi
if [ ! -f "$SSH_PUB_KEY_PATH" ]; then
    echo "ERROR: SSH public key not found at path: '$SSH_PUB_KEY_PATH'."
    exit 1
fi

# --- FINAL CORRECTION: Read the key's content into a variable ---
# Instead of passing a file path, we pass the key's actual content.
# This is more robust and avoids shell/pathing issues.
SSH_KEY_CONTENTS=$(cat "$SSH_PUB_KEY_PATH")

echo "--- Using Admin Username: '$ADMIN_USERNAME' and successfully read SSH Key ---"

# --- Network and NSG creation (unchanged) ---
# ... (The rest of the script is the same until the vm create command)
echo -e "\n--- Ensuring Public IP '$PUBLIC_IP_NAME' exists ---"
if ! az network public-ip show --resource-group "$RESOURCE_GROUP_NAME" --name "$PUBLIC_IP_NAME" &>/dev/null; then
    echo "Public IP '$PUBLIC_IP_NAME' not found. Creating..."
    az network public-ip create --resource-group "$RESOURCE_GROUP_NAME" --name "$PUBLIC_IP_NAME" --sku Standard --location "$LOCATION" --output none
    echo "Public IP '$PUBLIC_IP_NAME' created successfully."
else
    echo "Public IP '$PUBLIC_IP_NAME' already exists."
fi

echo -e "\n--- Ensuring Network Security Group '$NSG_NAME' exists ---"
if ! az network nsg show --resource-group "$RESOURCE_GROUP_NAME" --name "$NSG_NAME" &>/dev/null; then
    echo "NSG '$NSG_NAME' not found. Creating..."
    az network nsg create --resource-group "$RESOURCE_GROUP_NAME" --name "$NSG_NAME" --location "$LOCATION" --output none
    echo "NSG '$NSG_NAME' created successfully."
else
    echo "NSG '$NSG_NAME' already exists."
fi

declare -A rules
rules=( ["AllowSSH"]="22" ["AllowHTTP"]="80" ["AllowClickHouse"]="8123" )
priority=300
for rule_name in "${!rules[@]}"; do
    port="${rules[$rule_name]}"
    echo "--- Ensuring NSG rule '$rule_name' for port '$port' exists ---"
    if ! az network nsg rule show --resource-group "$RESOURCE_GROUP_NAME" --nsg-name "$NSG_NAME" --name "$rule_name" &>/dev/null; then
        echo "NSG rule '$rule_name' not found. Creating..."
        az network nsg rule create --resource-group "$RESOURCE_GROUP_NAME" --nsg-name "$NSG_NAME" --name "$rule_name" --protocol Tcp --direction Inbound --priority "$priority" --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range "$port" --access Allow --output none
        echo "NSG rule '$rule_name' created successfully."
    else
        echo "NSG rule '$rule_name' already exists."
    fi
    priority=$((priority + 10))
done


# --- Virtual Machine Creation (Idempotent) ---
echo -e "\n--- Ensuring Virtual Machine '$VM_NAME' exists ---"
if ! az vm show --resource-group "$RESOURCE_GROUP_NAME" --name "$VM_NAME" &>/dev/null; then
    echo "VM '$VM_NAME' not found. Creating..."
    az vm create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$VM_NAME" \
        --location "$LOCATION" \
        --image "$VM_IMAGE" \
        --size "$VM_SIZE" \
        --nsg "$NSG_NAME" \
        --public-ip-address "$PUBLIC_IP_NAME" \
        --admin-username "$ADMIN_USERNAME" \
        --ssh-key-values "$SSH_KEY_CONTENTS" \
        --output none
    echo "VM '$VM_NAME' created successfully."
else
    echo "VM '$VM_NAME' already exists."
fi

# --- Output Public IP Address ---
echo -e "\n--- Provisioning Complete. Retrieving Public IP Address ---"
PUBLIC_IP_ADDRESS=$(az network public-ip show --resource-group "$RESOURCE_GROUP_NAME" --name "$PUBLIC_IP_NAME" --query "ipAddress" -o tsv)

echo "--------------------------------------------------"
echo "VM Public IP Address:"
echo "$PUBLIC_IP_ADDRESS"
echo "--------------------------------------------------"
