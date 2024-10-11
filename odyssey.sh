#!/bin/bash


if [ "$EUID" -ne 0 ]; then
  echo "Silakan jalankan skrip ini sebagai root atau menggunakan sudo."
  exit 1
fi


install_tool() {
  TOOL=$1
  echo "$TOOL tidak ditemukan. Menginstal $TOOL..."
  apt-get update
  apt-get install -y $TOOL
}

if ! command -v git &> /dev/null; then
  install_tool git
fi

if ! command -v cargo &> /dev/null; then
  echo "Menginstal Rust untuk mendapatkan Cargo..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  # Memuat ulang shell agar Cargo dapat diakses
  source $HOME/.cargo/env
fi


echo "Mengunduh dan menjalankan skrip display.sh..."
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
sleep 5


echo "Mengkloning repositori Odyssey..."
git clone https://github.com/ithacaxyz/odyssey
cd odyssey || { echo "Gagal masuk ke direktori Odyssey"; exit 1; }


echo "Menginstal biner Odyssey..."
cargo install --path bin/odyssey


echo "Menjalankan node Odyssey..."
odyssey node --chain etc/odyssey-genesis.json --dev --http --http.api all


echo "Node Odyssey telah dijalankan di http://localhost:8545"
