#!/bin/bash

# Color definitions
RED='\033[41;97m'
GRN='\033[42;30m'
YLW='\033[43;30m'
BLU='\033[44;30m'
PRP='\033[45;97m'
CYN='\033[40;96m'
NC='\033[0m' # No Color

print_colored() {
    local color_code=$1
    local text=$2
    echo -e "${color_code}${text}${NC}"
}

display_colored_text() {
    print_colored "$CYN" "============================================================"
    print_colored "$GRN" "=======================  J.W.P.A  =========================="
    print_colored "$PRP" "================= @AirdropJP_JawaPride ====================="
    print_colored "$YLW" "=============== https://x.com/JAWAPRIDE_ID ================="
    print_colored "$RED" "============= https://linktr.ee/Jawa_Pride_ID =============="
    print_colored "$BLU" "============================================================"
}

# Display header
display_colored_text
sleep 3

# Interactive inputs
echo "Masukkan PRIVATE KEY Anda:"
read PRIVATE_KEY

echo "Masukkan Email GitHub Anda:"
read GITHUB_EMAIL

echo "Masukkan Username GitHub Anda:"
read GITHUB_USERNAME

echo "Masukkan alamat node operator Anda / YOU ADDRESS:"
read OPERATOR_ADDRESS

# Validate inputs
[[ -z "$PRIVATE_KEY" ]] && echo "Private Key tidak boleh kosong!" && exit 1
[[ -z "$GITHUB_EMAIL" ]] && echo "Email GitHub tidak boleh kosong!" && exit 1
[[ -z "$GITHUB_USERNAME" ]] && echo "Username GitHub tidak boleh kosong!" && exit 1
[[ -z "$OPERATOR_ADDRESS" ]] && echo "Alamat node operator tidak boleh kosong!" && exit 1

# Validate key format
if [[ ! "$PRIVATE_KEY" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
    echo "Private key tidak valid! Harap masukkan private key yang benar dalam format hexadecimal (0x + 64 karakter hex)."
    exit 1
fi

# Get VPS IP
VPS_IP=$(curl -s ifconfig.me)
if [[ -z "$VPS_IP" ]]; then
    echo "Gagal mendapatkan IP VPS!"
    exit 1
fi

# Confirmation
echo "Input berhasil diterima!"
echo "Private Key: ****${PRIVATE_KEY: -4}"
echo "GitHub Email: $GITHUB_EMAIL"
echo "GitHub Username: $GITHUB_USERNAME"
echo "Node Operator Address: $OPERATOR_ADDRESS"
echo "VPS IP: $VPS_IP"
echo "Apakah Anda ingin melanjutkan dengan instalasi? (y/n)"
read CONFIRMATION
[[ "$CONFIRMATION" != "y" ]] && echo "Instalasi dibatalkan!" && exit 0

echo "Memulai instalasi environment..."

# Install Python & eth-account
sudo apt-get install python3 python3-pip -y || exit 1
pip3 install eth-account || exit 1

# Install dependencies
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y

# Docker setup
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg -y; done
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo docker run hello-world || echo "⚠️ Docker test container gagal dijalankan."

# Drosera & Foundry
sudo apt install snap
curl -L https://app.drosera.io/install | bash
source ~/.bashrc && droseraup
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc && ps aux | grep anvil | awk '{print $2}' | xargs kill -9
foundryup
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc

DROSERA_PRIVATE_KEY=$PRIVATE_KEY drosera apply --eth-rpc-url https://holesky.gateway.tenderly.co

drosera dryrun

# Setup trap
mkdir -p ~/my-drosera-trap && cd ~/my-drosera-trap
git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_USERNAME"
forge init -t drosera-network/trap-foundry-template
bun init
bun install
forge build

# Apply Drosera config
DROSERA_PRIVATE_KEY=$PRIVATE_KEY drosera apply <<< "ofc"
echo -e '\nprivate_trap = true\nwhitelist = ["'"$OPERATOR_ADDRESS"'"]' >> ~/my-drosera-trap/drosera.toml

# Setelah Trap dideploy - Instruksi setelah apply
echo "Trap telah berhasil dideploy!"
echo "Langkah selanjutnya adalah memeriksa status dan bloom boost di dashboard Drosera."

# Menunggu 10 detik sebelum melanjutkan
echo "Menunggu 10 detik sebelum melanjutkan..."
sleep 10

# Menampilkan tampilan pengguna
clear
display_colored_text
echo "Menyiapkan konfigurasi Drosera..."
print_colored "$RED" "1. Hubungkan wallet EVM Drosera Anda ke dashboard: https://app.drosera.io/ paste address"
print_colored "$RED" "2. Klik pada 'Traps Owned' 'pilih yang private/lock/keduanya' untuk melihat Trap yang telah dideploy atau cari alamat Trap Anda."
print_colored "$RED" "3. Bloom Boost Trap Anda di Dashboard dengan menyetor Holesky ETH."
print_colored "$RED" "4. SETELAH KE LOGS AKHIR SILAHKAN PERGI KE WEB LAGI UNTUK OPT-IN."
print_colored "$RED" "5. OPT-IN BERGUNA UNTUK BLOCK/SYNC."

# Menunggu input dari pengguna sebelum melanjutkan
read -p "BACA PESAN DI ATAS UNTUK CONFIGURASI BOOST TRAP, TEKAN Y TERLEBIH DAHULU KARNA INI HANYA PERNINGANTAN? (Y/N): " completed

if [[ "$completed" == "Y" || "$completed" == "y" ]]; then
    # Menjalankan perintah Fetch Blocks setelah Trap dideploy
    echo "Menjalankan perintah 'drosera dryrun' untuk memeriksa status blok."
    drosera dryrun

    # Pertanyaan konfirmasi untuk memastikan semuanya selesai
    read -p "Apakah Anda sudah mengirim Trap dan melakukan Bloom Boost? (Y/N): " completed
    if [[ "$completed" == "Y" || "$completed" == "y" ]]; then
        echo "Proses selesai dan Trap telah berhasil diblooming!"
    else
        echo "Proses tidak selesai. Silakan ikuti instruksi dengan benar."
        exit 1
    fi
else
    echo "Proses belum selesai. Silakan ikuti instruksi dengan benar."
    exit 1
fi


# Download operator
cd ~
curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
sudo cp drosera-operator /usr/bin
drosera-operator --version

# Register node
drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key $PRIVATE_KEY

# Create service
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

# Firewall + start service
sudo ufw allow ssh
sudo ufw allow 31313/tcp
sudo ufw allow 31314/tcp
sudo ufw --force enable

sudo systemctl daemon-reload
sudo systemctl enable drosera
sudo systemctl start drosera

echo -e "${GRN}Drosera Node berhasil dijalankan!${NC}"

journalctl -u drosera.service -f
