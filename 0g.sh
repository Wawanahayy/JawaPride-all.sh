#!/bin/bash

curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

# Cek apakah Docker sudah terinstal
if ! command -v docker &> /dev/null
then
    echo "Docker tidak ditemukan. Silakan instal Docker terlebih dahulu."
    exit 1
fi

# Meminta private key dari pengguna
echo "Masukkan Private Key Anda: "
read -s PRIVATE_KEY

# Clone repository
if [ ! -d "0g-da-client" ]; then
    git clone https://github.com/0glabs/0g-da-client.git
fi
cd 0g-da-client || exit

# Hapus file envfile.env jika sudah ada
if [ -f "envfile.env" ]; then
    echo "Menghapus file envfile.env yang lama..."
    rm envfile.env
fi

# Build Docker Image
echo "Membangun Docker Image..."
docker build -t 0g-da-client -f combined.Dockerfile .

# Membuat file konfigurasi
cat > envfile.env <<EOL
COMBINED_SERVER_CHAIN_RPC=https://evmrpc-testnet.0g.ai
COMBINED_SERVER_PRIVATE_KEY=$PRIVATE_KEY
ENTRANCE_CONTRACT_ADDR=0x857C0A28A8634614BB2C96039Cf4a20AFF709Aa9

COMBINED_SERVER_RECEIPT_POLLING_ROUNDS=180
COMBINED_SERVER_RECEIPT_POLLING_INTERVAL=1s
COMBINED_SERVER_TX_GAS_LIMIT=2000000
COMBINED_SERVER_USE_MEMORY_DB=true
COMBINED_SERVER_KV_DB_PATH=/runtime/
COMBINED_SERVER_TimeToExpire=2592000
DISPERSER_SERVER_GRPC_PORT=51001
BATCHER_DASIGNERS_CONTRACT_ADDRESS=0x0000000000000000000000000000000000001000
BATCHER_FINALIZER_INTERVAL=20s
BATCHER_CONFIRMER_NUM=3
BATCHER_MAX_NUM_RETRIES_PER_BLOB=3
BATCHER_FINALIZED_BLOCK_COUNT=50
BATCHER_BATCH_SIZE_LIMIT=500
BATCHER_ENCODING_INTERVAL=3s
BATCHER_ENCODING_REQUEST_QUEUE_SIZE=1
BATCHER_PULL_INTERVAL=10s
BATCHER_SIGNING_INTERVAL=3s
BATCHER_SIGNED_PULL_INTERVAL=20s
BATCHER_EXPIRATION_POLL_INTERVAL=3600
BATCHER_ENCODER_ADDRESS=DA_ENCODER_SERVER
BATCHER_ENCODING_TIMEOUT=300s
BATCHER_SIGNING_TIMEOUT=60s
BATCHER_CHAIN_READ_TIMEOUT=12s
BATCHER_CHAIN_WRITE_TIMEOUT=13s
EOL

echo "Konfigurasi berhasil dibuat."

# Menjalankan Docker Container
echo "Menjalankan 0g DA Client Node..."
docker run -d --env-file envfile.env --name 0g-da-client -v ./run:/runtime -p 51001:51001 0g-da-client combined

echo "Node berhasil dijalankan! log real-time..."
docker logs -f 0g-da-client
