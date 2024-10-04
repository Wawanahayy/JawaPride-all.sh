#!/bin/bash

# Panggil display.sh untuk menampilkan pesan loading
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

# Clone the repository
echo "Mengunduh repositori Sui Meta Miner..."
git clone https://github.com/Wawanahayy/sui_meta_miner

# Navigate into the project directory
cd sui_meta_miner

# Menampilkan pesan saat menginstal dependencies
echo "Menginstal dependensi, harap tunggu..."
npm install

# Menampilkan pesan saat menginstal suidouble
echo "Menginstal suidouble, harap tunggu..."
npm install suidouble

# Display success message
echo "Setup Sui Meta Miner selesai dengan sukses!"

