#!/bin/bash

# Exit on error.
set -e

# Define constants.
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color
readonly OS_TARGET="Debian GNU/Linux 11 (bullseye)"
readonly RED='\033[0;31m'

echo -e "${BLUE}Setting up IoT Edge runtime...${NC}"

# Check script parameters.
echo -e "${BLUE}Checking script parameters...${NC}"
aziot_hub_connection_string=$1
if [ -z ${aziot_hub_connection_string+x} ]; then
    echo -e "${RED}Azure IoT Hub connection string must be set as first positional parameter. Exiting...${NC}" >&2
    exit 1
fi

# Check targeted operating system.
echo -e "${BLUE}Checking operating system...${NC}"
os_current=$(cat /etc/os-release | grep PRETTY_NAME | tr "=" "\n" | tr -d '"' | sed -n "2 p")
if [ "$os_current" != "$OS_TARGET" ]; then
    echo -e "${RED}Operating system '${os_current}' is not supported (Supported: '${OS_TARGET}'). Exiting...${NC}" >&2
    exit 1
fi

# Add Microsoft package repository and trust its signing key.
echo -e "${BLUE}Adding Microsoft package repository and trusting its signing key...${NC}"
curl https://packages.microsoft.com/config/debian/11/prod.list > ./microsoft-prod.list
sudo mv ./microsoft-prod.list /etc/apt/sources.list.d/

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv ./microsoft.gpg /etc/apt/trusted.gpg.d/

# Install Moby engine.
echo -e "${BLUE}Installing Moby Engine...${NC}"
sudo apt-get update; sudo apt-get install moby-engine

# Install Azure IoT Identity Service.
# Raspberry Pi OS Bullseye is currently not supported, but packages can be manually installed.
# See:
# - https://docs.microsoft.com/en-us/answers/questions/515023/about-azure-iot-edge-packages-for-debian-11bullsey.html
# - https://docs.microsoft.com/en-us/azure/iot-edge/support?view=iotedge-2020-11#operating-systems
echo -e "${BLUE}Installing Azure IoT Identity Service...${NC}"
aziot_identity_service="https://github.com/Azure/azure-iotedge/releases/download/1.2.8/aziot-identity-service_1.2.6-1_debian11_arm64.deb"
curl -L $aziot_identity_service -o aziot-identity-service.deb
sudo apt-get install ./aziot-identity-service.deb
sudo apt --fix-broken install # Required to install missing dependencies.
rm ./aziot-identity-service.deb

# Install Azure IoT Edge.
# Raspberry Pi OS Bullseye is currently not supported, but packages can be manually installed.
# See:
# - https://docs.microsoft.com/en-us/answers/questions/515023/about-azure-iot-edge-packages-for-debian-11bullsey.html
# - https://docs.microsoft.com/en-us/azure/iot-edge/support?view=iotedge-2020-11#operating-systems
echo -e "${BLUE}Installing Azure IoT Edge...${NC}"
aziot_edge="https://github.com/Azure/azure-iotedge/releases/download/1.2.8/aziot-edge_1.2.8-1_debian11_arm64.deb"
curl -L $aziot_edge -o aziot-edge.deb
sudo apt-get install ./aziot-edge.deb
rm ./aziot-edge.deb

# Configure Azure IoT Edge.
echo -e "${BLUE}Configuring Azure IoT Edge...${NC}"
sudo iotedge config mp --force --connection-string $aziot_hub_connection_string
sudo iotedge config apply -c '/etc/aziot/config.toml'

# Print Azure IoT Edge system status.
echo -e "${BLUE}Printing Azure IoT Edge system status...${NC}"
iotedge system status

# Perform Azure IoT Edge checks.
echo -e "${BLUE}Performing Azure IoT Edge checks...${NC}"
sudo iotedge check

echo -e "${BLUE}Setup completed.${NC}"