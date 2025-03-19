#!/bin/bash

set -e  # Hentikan skrip jika ada error

# Fungsi untuk menampilkan teks berwarna
printf_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

# Fungsi untuk menampilkan teks berwarna di bagian atas skrip
display_colored_text() {
    printf_colored "42;30" "========================================================="
    printf_colored "46;30" "========================================================="
    printf_colored "45;97" "======================   T3RN   ========================="
    printf_colored "43;30" "============== create all by JAWA-PRIDE  ================"
    printf_colored "41;97" "=========== https://t.me/AirdropJP_JawaPride ============"
    printf_colored "44;30" "========================================================="
    printf_colored "42;97" "========================================================="
}

# Tampilkan teks berwarna dan beri jeda hanya saat pertama kali dijalankan
display_colored_text
sleep 5

# Buat direktori t3rn
echo "[1/7] Membuat direktori t3rn..."
mkdir -p ~/t3rn && cd ~/t3rn

# Download versi terbaru dari executor
echo "[2/7] Mengunduh executor terbaru..."
LATEST_TAG=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
wget -q https://github.com/t3rn/executor-release/releases/download/$LATEST_TAG/executor-linux-$LATEST_TAG.tar.gz

# Ekstrak binary
echo "[3/7] Mengekstrak binary..."
tar -xzf executor-linux-*.tar.gz

# Konfigurasi RPC Endpoints
echo "[4/7] Mengatur RPC Endpoints..."
cat <<EOF | sudo tee /etc/t3rn-executor.env > /dev/null
RPC_ENDPOINTS='{"l2rn": ["https://b2n.rpc.caldera.xyz/http"], "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"], "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"], "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"], "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]}'
EOF

# Minta input Private Key dari user
echo "[INFO] Masukkan Private Key Anda: "
read -s PRIVATE_KEY  # Input private key tanpa terlihat

# Tanya pengguna tentang batas maksimal harga gas L3
read -p "[?] Masukkan batas maksimal harga gas L3 (default: 100): " MAX_L3_GAS_PRICE
MAX_L3_GAS_PRICE=${MAX_L3_GAS_PRICE:-100}  # Gunakan 100 jika input kosong

# Buat service systemd
echo "[5/7] Membuat systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/t3rn-executor.service > /dev/null
[Unit]
Description=t3rn Executor Service
After=network.target

[Service]
User=root
WorkingDirectory=$HOME/t3rn/executor/executor/bin
ExecStart=$HOME/t3rn/executor/executor/bin/executor
Restart=always
RestartSec=10
Environment=ENVIRONMENT=testnet
Environment=LOG_LEVEL=debug
Environment=LOG_PRETTY=false
Environment=EXECUTOR_PROCESS_BIDS_ENABLED=true
Environment=EXECUTOR_PROCESS_ORDERS_ENABLED=true
Environment=EXECUTOR_PROCESS_CLAIMS_ENABLED=true
Environment=EXECUTOR_MAX_L3_GAS_PRICE=$MAX_L3_GAS_PRICE
Environment=PRIVATE_KEY_LOCAL=$PRIVATE_KEY
Environment=ENABLED_NETWORKS=arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn
EnvironmentFile=/etc/t3rn-executor.env
Environment=EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true

[Install]
WantedBy=multi-user.target
EOF

# Reload dan mulai service
echo "[6/7] Memulai service..."
sudo systemctl daemon-reload
sudo systemctl enable t3rn-executor.service
sudo systemctl start t3rn-executor.service

# Cek status service dan tampilkan logs secara real-time
echo "✅ Instalasi selesai! Menampilkan logs real-time..."
sudo journalctl -u t3rn-executor.service -f --no-hostname -o cat
