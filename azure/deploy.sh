#!/bin/bash

# Exit on error.
set -e

# Define constants.
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color
readonly RED='\033[0;31m'

# Define variables.
env_file=$(realpath "./iot-edge/.env")
resource_group_name="azure-iot-edge-raspberry-pi"
location="westeurope"
random=$(uuidgen | tr -d "-" | head -c 10)
acr_name="acr${random}"
iot_hub_name="iothub${random}"
iot_edge_device_id="raspberry-pi"
iot_edge_module_configuration_file="./iot-edge/modules/sensehat/module.json"

echo -e "${BLUE}Deploying to Azure...${NC}"

# Create resource group.
echo -e "${BLUE}Creating resource group '${resource_group_name}'...${NC}"
az group create -n $resource_group_name -l $location

# Create container registry.
echo -e "${BLUE}Creating container registry '${acr_name}'...${NC}"
az acr create --resource-group $resource_group_name --name $acr_name --sku "Basic" --admin-enabled

# Create IoT hub.
echo -e "${BLUE}Creating IoT hub '${iot_hub_name}'...${NC}"
az iot hub create --resource-group $resource_group_name --name $iot_hub_name --sku "F1" --partition-count 2

# Register IoT edge device.
echo -e "${BLUE}Register IoT edge device '${iot_edge_device_id}'...${NC}"
az iot hub device-identity create --hub-name $iot_hub_name --device-id $iot_edge_device_id --edge-enabled

# Create .env file.
echo -e "${BLUE}Creating env file in '${env_file}'...${NC}"
acr_address="${acr_name}.azurecr.io"
read acr_username acr_password <<< $(az acr credential show --name $acr_name --query "[username,passwords[0].value]" --output tsv | tr "\n" " ")
cat > $env_file <<- EOM
CONTAINER_REGISTRY_NAME=${acr_name}
CONTAINER_REGISTRY_ADDRESS=${acr_address}
CONTAINER_REGISTRY_USERNAME=${acr_username}
CONTAINER_REGISTRY_PASSWORD=${acr_password}
EOM

# Updating IoT edge module configuration.
echo -e "${BLUE}Updating IoT edge module configuration...${NC}"
sed -i "s/\$CONTAINER_REGISTRY_ADDRESS/${acr_address}/" $iot_edge_module_configuration_file

echo -e "${BLUE}Deployment completed.${NC}"