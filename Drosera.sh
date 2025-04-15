#!/bin/bash

# Function to print colored text
print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

# Function to display colored text
display_colored_text() {
    print_colored "40;96" "============================================================"  
    print_colored "42;37" "=======================  J.W.P.A  ==========================" 
    print_colored "45;97" "================= @AirdropJP_JawaPride =====================" 
    print_colored "43;30" "=============== https://x.com/JAWAPRIDE_ID =================" 
    print_colored "41;97" "============= https://linktr.ee/Jawa_Pride_ID ==============" 
    print_colored "44;30" "============================================================" 
}

# Display the initial colored text
display_colored_text

# Wait for 3 seconds before continuing
sleep 3

# Read user input for required fields
echo "Masukkan PRIVATE KEY Anda:"
read PRIVATE_KEY

echo "Masukkan Email GitHub Anda:"
read GITHUB_EMAIL

echo "Masukkan alamat node operator Anda (tekan ENTER untuk menggunakan alamat dari PRIVATE KEY):"
read OPERATOR_ADDRESS

# If operator address is not provided, extract from private key
if [ -z "$OPERATOR_ADDRESS" ]; then
    OPERATOR_ADDRESS=$(python3 -c "
from eth_account import Account
acct = Account.from_key('$PRIVATE_KEY')
print(acct.address)
")
    echo "Menggunakan alamat operator dari PRIVATE KEY: $OPERATOR_ADDRESS"
fi

# Verify the private key format (ensure it's hexadecimal)
if [[ ! "$PRIVATE_KEY" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
    echo "Private key tidak valid! Harap masukkan private key yang benar dalam format hexadecimal (0x diikuti oleh 64 karakter hex)."
    exit 1
fi

# Proceed with the installation only after inputs are received
echo "Input berhasil diterima, melanjutkan dengan instalasi..."

# Install necessary packages
sudo apt-get install python3 python3-pip -y > /dev/null 2>&1
pip3 install eth-account > /dev/null 2>&1

# Install updates and other required packages
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y

# Install Docker
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo docker run hello-world

# Install Drosera
curl -L https://app.drosera.io/install | bash
source /root/.bashrc && droseraup

# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
source /root/.bashrc && foundryup

# Install Bun
curl -fsSL https://bun.sh/install | bash
source /root/.bashrc

# Setup Drosera trap directory
mkdir -p ~/my-drosera-trap && cd ~/my-drosera-trap
git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_USERNAME"
forge init -t drosera-network/trap-foundry-template
bun install
forge build

# Apply Drosera with private key
DROSERA_PRIVATE_KEY=$PRIVATE_KEY drosera apply <<< "ofc"

# Add private key and operator address to drosera.toml
echo -e '\nprivate_trap = true\nwhitelist = ["'"$OPERATOR_ADDRESS"'"]' >> ~/my-drosera-trap/drosera.toml
cd ~/my-drosera-trap
DROSERA_PRIVATE_KEY=$PRIVATE_KEY drosera apply

# Download Drosera operator and install
cd ~
curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
sudo cp drosera-operator /usr/bin
drosera-operator --version

# Register Drosera node
drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key $PRIVATE_KEY

# Create systemd service for Drosera
sudo tee /etc/systemd/system/drosera.service > /dev/null <<EOF
[Unit]
Description=Drosera Node Service
After=network-online.target

[Service]
User=$USER
Restart=always
RestartSec=15
LimitNOFILE=65535
ExecStart=$(which drosera-operator) node --db-file-path $HOME/.drosera.db --network-p2p-port 31313 --server-port 31314 \
    --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com \
    --eth-backup-rpc-url https://1rpc.io/holesky \
    --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \
    --eth-private-key $PRIVATE_KEY \
    --listen-address 0.0.0.0 \
    --network-external-p2p-address $VPS_IP \
    --disable-dnr-confirmation true

[Install]
WantedBy=multi-user.target
EOF

# Setup firewall and start Drosera service
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 31313/tcp
sudo ufw allow 31314/tcp
sudo ufw --force enable

sudo systemctl daemon-reload
sudo systemctl enable drosera
sudo systemctl start drosera

# Display Drosera logs
journalctl -u drosera.service -f
