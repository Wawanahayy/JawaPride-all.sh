#!/bin/bash

print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

display_colored_text() {
    print_colored "40;96" "============================================================"  
    print_colored "42;37" "=======================  J.W.P.A  ==========================" 
    print_colored "45;97" "================= @AirdropJP_JawaPride =====================" 
    print_colored "43;30" "=============== https://x.com/JAWAPRIDE_ID =================" 
    print_colored "41;97" "============= https://linktr.ee/Jawa_Pride_ID ==============" 
    print_colored "44;30" "============================================================" 
}

display_colored_text
sleep 5

echo -e "\nMemperbarui dan mengupgrade sistem..."
apt update && apt upgrade -y

# Cleanup previous files
rm -rf blockmesh-cli.tar.gz target

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "Menginstal Docker..."
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
else
    echo "Docker sudah terinstal, melewati..."
fi

# Install Docker Compose
echo "Menginstal Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create target directory for extraction
mkdir -p target/release

# Download and extract BlockMesh CLI
echo "Mengunduh dan mengekstrak BlockMesh CLI..."
curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.324/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release

# Verify extraction
if [[ ! -f target/release/blockmesh-cli ]]; then
    echo "Error: blockmesh-cli binary not found in target/release. Exiting..."
    exit 1
fi

# Prompt for email and password
read -p "Masukkan email BlockMesh Anda: " email
read -s -p "Masukkan password BlockMesh Anda: " password
echo ""

# Menggunakan trap untuk menangkap Ctrl+C dan keluar dengan baik
trap "echo 'Keluar...'; exit 0" SIGINT

# Run the Docker container with the BlockMesh CLI
echo "Membuat kontainer Docker untuk BlockMesh CLI..."
docker run --rm \
    --name blockmesh-cli-container \
    -v "$(pwd)/target/release:/app" \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"
