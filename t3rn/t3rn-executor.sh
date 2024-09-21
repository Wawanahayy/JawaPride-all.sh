#!/bin/bash

# Fungsi untuk menampilkan teks berwarna
print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

# Fungsi untuk menampilkan banner berwarna
display_colored_text() {
    print_colored "42;30" "========================================================="
    print_colored "46;30" "========================================================="
    print_colored "45;97" "======================   T3EN   ========================="
    print_colored "43;30" "============== create all by JAWA-PRIDE  ================"
    print_colored "41;97" "=========== https://t.me/AirdropJP_JawaPride ============"
    print_colored "44;30" "========================================================="
    print_colored "42;97" "========================================================="
}

# Tampilkan banner berwarna
display_colored_text
sleep 5

# Fungsi log untuk mencetak pesan dengan level yang berbeda
log() {
    local level=$1
    local message=$2
    echo "[$level] $message"
}

# Pertanyaan untuk bergabung dengan channel Telegram
read -p "Apakah Anda sudah bergabung dengan channel kami Channel: @AirdropJP_JawaPride https://t.me/AirdropJP_JawaPride? (y/n): " join_channel

if [[ "$join_channel" == "y" || "$join_channel" == "Y" ]]; then
    echo "Terima kasih telah bergabung dengan channel kami!"
else
    echo "Kami sarankan Anda bergabung dengan channel untuk mendapatkan informasi terbaru."
    sleep 5
    exit 1
fi

# Minta pengguna memasukkan kunci privat
read -sp "Masukkan kunci privat Anda: " PRIVATE_KEY_LOCAL
echo # Untuk mencetak baris baru setelah input

# Periksa apakah kunci privat sudah diatur
if [[ -z "$PRIVATE_KEY_LOCAL" ]]; then
    echo "Error: Kunci privat belum diatur. Harap masukkan kunci privat yang valid."
    exit 1
fi

# Update sistem dan unduh binary
cd $HOME
rm -rf executor
sudo apt -q update
sudo apt -qy upgrade

EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/v0.21.1/executor-linux-v0.21.1.tar.gz"
EXECUTOR_FILE="executor-linux-v0.21.1.tar.gz"
echo "Mengunduh binary Executor dari $EXECUTOR_URL..."
curl -L -o $EXECUTOR_FILE $EXECUTOR_URL
if [ $? -ne 0 ]; then
    echo "Gagal mengunduh binary Executor. Harap periksa koneksi internet Anda dan coba lagi."
    exit 1
fi

echo "Mengekstrak binary..."
tar -xzvf $EXECUTOR_FILE
rm -rf $EXECUTOR_FILE
cd executor/executor/bin
echo "Binary berhasil diunduh dan diekstrak."
echo

# Atur variabel lingkungan
export NODE_ENV=testnet
export LOG_LEVEL=debug
export LOG_PRETTY=false
export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"
export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn'

# Atur URL RPC
export RPC_ENDPOINTS_ARBT='https://sepolia-rollup.arbitrum.io/rpc'
export RPC_ENDPOINTS_BSSP='https://sepolia.base.org/rpc'
export RPC_ENDPOINTS_BLSS='https://sepolia.blast.io/'
export RPC_ENDPOINTS_OPSP='https://optimism-sepolia.drpc.org'
export RPC_ENDPOINTS_L1RN='https://brn.rpc.caldera.xyz/http'

# Jalankan executor
echo "Memulai Executor..."
./executor --trace-warnings
if [ $? -ne 0 ]; then
    echo "Executor gagal dimulai. Harap periksa log untuk informasi lebih lanjut."
    exit 1
fi
