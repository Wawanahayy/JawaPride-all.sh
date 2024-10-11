#!/bin/bash

curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
sleep 5

# Mengupdate dan menginstal dependensi yang diperlukan
echo "Mengupdate sistem dan menginstal dependensi..."
apt update && apt upgrade -y
apt install -y git cargo docker.io

# Mengkloning repository Odyssey
echo "Mengkloning repository Odyssey..."
git clone https://github.com/ithacaxyz/odyssey
cd odyssey || { echo "Gagal masuk ke direktori odyssey"; exit 1; }

# Menginstal Odyssey
echo "Menginstal Odyssey..."
cargo install --path bin/odyssey
if [ $? -ne 0 ]; then
    echo "Terjadi kesalahan saat menginstal Odyssey!"
    exit 1
fi

# Menjalankan Node Odyssey dengan konfigurasi pengembangan
echo "Menjalankan Node Odyssey dengan konfigurasi pengembangan..."
odyssey node --chain etc/odyssey-genesis.json --dev --http --http.api all &
sleep 10

# Menjalankan Node Eksekusi Odyssey
echo "Menjalankan Node Eksekusi Odyssey..."
odyssey node \
    --chain etc/odyssey-genesis.json \
    --rollup.sequencer-http http://localhost:9551 \
    --http \
    --ws \
    --authrpc.port 9551 \
    --authrpc.jwtsecret /path/to/your/jwt.hex &
sleep 10

# Menjalankan op-node dengan konfigurasi Odyssey
echo "Menjalankan op-node dengan konfigurasi Odyssey..."
cd odyssey/ || { echo "Gagal masuk ke direktori odyssey"; exit 1; }
op-node \
    --rollup.config ./etc/odyssey-rollup.json \
    --l1=https://sepolia.infura.io/v3/\
    --l2=http://localhost:9551 \
    --l2.jwt-secret=/path/to/your/jwt.hex \
    --rpc.addr=0.0.0.0 \
    --rpc.port=7000 \
    --l1.trustrpc &

echo "Odyssey dan op-node telah berjalan. Anda dapat memeriksa log untuk informasi lebih lanjut."
