#!/bin/bash

echo "========================================"
echo "   LayerEdge Light Node Auto Setup 🚀   "
echo "========================================"

# Minta input private key
read -p "Masukkan PRIVATE_KEY: " PRIVATE_KEY

# Periksa apakah PRIVATE_KEY kosong
if [ -z "$PRIVATE_KEY" ]; then
    echo "PRIVATE_KEY tidak boleh kosong!"
    exit 1
fi

# Update & install dependensi
echo "[1] Mengupdate sistem & menginstal dependensi..."
apt update && apt upgrade -y
apt install -y curl git build-essential iptables ufw

# Install Go versi terbaru
echo "[2] Menginstal Go versi terbaru..."
wget https://go.dev/dl/go1.23.1.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Install Rust versi terbaru
echo "[3] Menginstal Rust versi terbaru..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Install Risc0 Toolchain
echo "[4] Menginstal Risc0 Toolchain..."
curl -L https://risczero.com/install | bash
source ~/.bashrc
rzup install

# Clone repository
echo "[5] Meng-clone Light Node Repository..."
git clone https://github.com/Layer-Edge/light-node.git
cd light-node || exit

# Buat file .env
echo "[6] Mengatur environment variables..."
cat <<EOF > .env
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY='$PRIVATE_KEY'
EOF

# Build dan jalankan Merkle Service
echo "[7] Memulai Merkle Service..."
cd risc0-merkle-service || exit
cargo build && cargo run &

# Tunggu beberapa detik agar Merkle Service berjalan
sleep 10

# Build ulang dan jalankan Light Node
echo "[8] Menjalankan Light Node..."
cd ..
go mod tidy
go build
./light-node &

echo "✅ Light Node Berjalan! Cek status CLI di: dashboard.layeredge.io"
