#!/bin/bash

curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

echo "Masukkan PRIVATE KEY Anda:"
read PRIVATE_KEY

echo "Masukkan IP VPS Anda:"
read VPS_IP

echo "Masukkan Email GitHub Anda:"
read GITHUB_EMAIL

echo "Masukkan Username GitHub Anda:"
read GITHUB_USERNAME

if [ -z "$PRIVATE_KEY" ]; then
    echo "Private Key tidak boleh kosong!"
    exit 1
fi

if [ -z "$VPS_IP" ]; then
    echo "IP VPS tidak boleh kosong!"
    exit 1
fi

if [ -z "$GITHUB_EMAIL" ]; then
    echo "Email GitHub tidak boleh kosong!"
    exit 1
fi

if [ -z "$GITHUB_USERNAME" ]; then
    echo "Username GitHub tidak boleh kosong!"
    exit 1
fi

sudo apt-get install python3 python3-pip -y > /dev/null 2>&1
pip3 install eth-account > /dev/null 2>&1

OPERATOR_ADDRESS=$(python3 -c "
from eth_account import Account
acct = Account.from_key('$PRIVATE_KEY')
print(acct.address)
")

echo "OPERATOR_ADDRESS: $OPERATOR_ADDRESS"

sudo apt-get update && sudo apt-get upgrade -y
sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y

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

curl -L https://app.drosera.io/install | bash
source /root/.bashrc && droseraup

curl -L https://foundry.paradigm.xyz | bash
source /root/.bashrc && foundryup

curl -fsSL https://bun.sh/install | bash
source /root/.bashrc

mkdir -p ~/my-drosera-trap && cd ~/my-drosera-trap
git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_USERNAME"
forge init -t drosera-network/trap-foundry-template
bun install
forge build

DROSERA_PRIVATE_KEY=$PRIVATE_KEY drosera apply <<< "ofc"

echo -e '\nprivate_trap = true\nwhitelist = ["'"$OPERATOR_ADDRESS"'"]' >> ~/my-drosera-trap/drosera.toml
cd ~/my-drosera-trap
DROSERA_PRIVATE_KEY=$PRIVATE_KEY drosera apply

cd ~
curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
sudo cp drosera-operator /usr/bin
drosera-operator --version

drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key $PRIVATE_KEY

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

sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 31313/tcp
sudo ufw allow 31314/tcp
sudo ufw --force enable

sudo systemctl daemon-reload
sudo systemctl enable drosera
sudo systemctl start drosera

curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

journalctl -u drosera.service -f
