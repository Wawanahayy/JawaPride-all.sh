#!/bin/bash

# 1. Clone the DA Node Repository
echo "Cloning 0G DA Node repository..."
git clone https://github.com/0glabs/0g-da-node.git
cd 0g-da-node || exit

# 2. Generate BLS Private Key
echo "Generating BLS private key..."
BLS_PRIVATE_KEY=$(cargo run --bin key-gen | grep -oP '(?<=Generated BLS key: )\S+')

# Check if key was generated successfully
if [ -z "$BLS_PRIVATE_KEY" ]; then
    echo "❌ Failed to generate BLS private key. Exiting..."
    exit 1
fi

echo "✅ BLS Private Key Generated: $BLS_PRIVATE_KEY"

# 3. User Inputs Ethereum Private Key
echo "Masukkan Ethereum Private Key Anda:"
read -s ETH_PRIVATE_KEY
echo "✅ Ethereum Private Key berhasil disimpan."

# 4. Create config.toml
echo "Membuat config.toml..."
cat <<EOF > config.toml
log_level = "info"

data_path = "/data"

# Path to downloaded params folder
encoder_params_dir = "/params"

# gRPC server listen address
grpc_listen_address = "0.0.0.0:34000"

# Ethereum RPC endpoint
eth_rpc_endpoint = "https://evmrpc-testnet.0g.ai"

# Public gRPC service socket address (Replace with your public IP or DNS)
socket_address = "<public_ip/dns>:34000"

# DA contract details (Testnet)
da_entrance_address = "0x857C0A28A8634614BB2C96039Cf4a20AFF709Aa9"
start_block_number = 940000

# Menggunakan private key yang dibuat/dimasukkan
signer_bls_private_key = "$BLS_PRIVATE_KEY"
signer_eth_private_key = "$ETH_PRIVATE_KEY"
miner_eth_private_key = "$ETH_PRIVATE_KEY"

# Enable Data Availability Sampling (DAS)
enable_das = "true"
EOF

echo "✅ config.toml berhasil dibuat."

# 5. Build & Run with Docker
echo "Building dan menjalankan DA Node dengan Docker..."
docker build -t 0g-da-node .
docker run -d --name 0g-da-node 0g-da-node

echo "🎉 0G DA Node berhasil di-setup!"

# 6. Cek Log Secara Real-Time
echo "Menampilkan log real-time dari 0G DA Node..."
sleep 5  # Tunggu sebentar agar container benar-benar mulai
docker logs -f 0g-da-node
