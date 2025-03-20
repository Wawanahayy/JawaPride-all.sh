#!/bin/bash

# Pastikan script berjalan sebagai root
if [ "$(id -u)" -ne 0 ]; then
    echo "Harap jalankan sebagai root! Gunakan: sudo ./setup_light_node.sh"
    exit 1
fi

echo "🚀 Menginstal dan Menjalankan LayerEdge CLI Light Node..."

# Update dan instal dependensi utama
echo "📦 Mengupdate sistem dan menginstal dependensi..."
apt update && apt upgrade -y
apt install -y curl git build-essential clang pkg-config libssl-dev jq

# Instal Go (minimal versi 1.18)
echo "🛠 Menginstal Go..."
GO_VERSION="1.21.3"
wget https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
go version

# Instal Rust (minimal versi 1.81.0)
echo "🛠 Menginstal Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustc --version

# Instal Risc0 Toolchain
echo "🔧 Menginstal Risc0 Toolchain..."
curl -L https://risczero.com/install | bash && source ~/.bashrc
rzup install

# Clone repository Light Node
echo "📥 Meng-clone repository LayerEdge Light Node..."
git clone https://github.com/Layer-Edge/light-node.git
cd light-node || exit 1

# Konfigurasi environment variables
echo "⚙️ Mengatur environment variables..."
cat <<EOF > .env
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY='cli-node-private-key'
EOF

echo "🔐 Pastikan PRIVATE_KEY sudah diperbarui dengan yang benar!"

# Build dan jalankan Merkle Service
echo "🛠 Membangun dan menjalankan Merkle Service..."
cd risc0-merkle-service || exit 1
cargo build && cargo run &

# Build dan jalankan Light Node
echo "🚀 Menjalankan Light Node..."
cd ..
go build
./light-node &

echo "✅ Instalasi dan setup selesai!"
echo "🌍 Cek status di: https://dashboard.layeredge.io"
