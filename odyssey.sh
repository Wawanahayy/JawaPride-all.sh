#!/bin/bash

curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
sleep 5

# Memastikan bahwa skrip dijalankan dengan hak akses root
if [ "$EUID" -ne 0 ]; then
  echo "Silakan jalankan skrip ini sebagai root atau menggunakan sudo."
  exit 1
fi

# Mengkloning repositori Odyssey
echo "Mengkloning repositori Odyssey..."
git clone https://github.com/ithacaxyz/odyssey
cd odyssey || exit

# Menginstal biner Odyssey
echo "Menginstal biner Odyssey..."
cargo install --path bin/odyssey

# Menjalankan node Odyssey dengan konfigurasi pengembangan
echo "Menjalankan node Odyssey..."
odyssey node --chain etc/odyssey-genesis.json --dev --http --http.api all

# Menampilkan pesan selesai
echo "Node Odyssey telah dijalankan di http://localhost:8545"
