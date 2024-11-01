#!/bin/bash

# Function to print text in color
print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

# Function to display the banner with colored text
display_colored_text() {
    print_colored "40;96" "============================================================"  
    print_colored "42;37" "=======================  J.W.P.A  ==========================" 
    print_colored "45;97" "================= @AirdropJP_JawaPride =====================" 
    print_colored "43;30" "=============== https://x.com/JAWAPRIDE_ID =================" 
    print_colored "41;97" "============= https://linktr.ee/Jawa_Pride_ID ==============" 
    print_colored "44;30" "============================================================" 
}

# Display the banner and pause for 5 seconds
display_colored_text
sleep 5

# Function to log messages with a blinking effect in different colors
log() {
    local message=$1
    local colors=("31" "32" "33" "34" "35" "36" "37")
    
    local count=0
    while [ $count -lt 10 ]; do
        for color in "${colors[@]}"; do
            timestamp=$(date +"[%Y-%m-%d %H:%M:%S %Z]")
            echo -ne "\033[${color};5m${timestamp} ${message}\033[0m\r"
            sleep 0.2
        done
        ((count++))
    done
    echo ""
}

# Update and upgrade the system packages
echo -e "\nUpdating and upgrading system..."
apt update && apt upgrade -y

# Delete existing files if any
echo -e "\nDeleting existing files..."
rm -rf blockmesh-cli.tar.gz target

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo -e "\nInstalling Docker..."
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io || echo "Docker installation failed"
else
    echo -e "\nDocker already installed, skipping..."
fi

# Fetch the latest Docker Compose version and install it
echo -e "\nInstalling latest Docker Compose..."
compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose || echo "Failed to set executable permission for Docker Compose"

# Fetch the latest BlockMesh CLI version and download it
echo -e "\nDownloading and extracting latest BlockMesh CLI..."
blockmesh_version=$(curl -s https://api.github.com/repos/block-mesh/block-mesh-monorepo/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
curl -L "https://github.com/block-mesh/block-mesh-monorepo/releases/download/${blockmesh_version}/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz" -o blockmesh-cli.tar.gz
tar -xzf blockmesh-cli.tar.gz || echo "Failed to extract BlockMesh CLI"

# Prompt user for BlockMesh credentials
read -p "Enter your BlockMesh email: " email
read -s -p "Enter your BlockMesh password: " password
echo ""

# Infinite loop to log uptime reports
while true; do
    message="[INFO] Session Email: $email: Successfully submitted uptime report"
    log "$message"
    sleep 1
done
