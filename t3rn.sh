#!/bin/bash

# Jalur penyimpanan skrip
SCRIPT_PATH="$HOME/t3rn.sh"
LOGFILE="$HOME/executor/executor.log"
EXECUTOR_DIR="$HOME/executor"

# Periksa apakah skrip dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan hak akses root."
    echo "Silakan coba gunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan kembali skrip ini."
    exit 1
fi

# Fungsi untuk mencetak teks berwarna
print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

# Fungsi untuk menampilkan teks berwarna di bagian atas skrip
display_colored_text() {
    print_colored "42;30" "========================================================="
    print_colored "46;30" "========================================================="
    print_colored "45;97" "======================   T3EN   ========================="
    print_colored "43;30" "============== create all by JAWA-PRIDE  ================"
    print_colored "41;97" "=========== https://t.me/AirdropJP_JawaPride ============"
    print_colored "44;30" "========================================================="
    print_colored "42;97" "========================================================="
}

# Tampilkan teks berwarna dan beri jeda hanya saat pertama kali dijalankan
display_colored_text
sleep 5

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        display_colored_text  # Menampilkan header berwarna setiap kali menu muncul
        
        echo "================================================================"
        echo "Untuk keluar dari skrip, tekan Ctrl + C pada keyboard."
        echo "Pilih operasi yang ingin dijalankan:"
        echo "1) Jalankan skrip"
        echo "2) Lihat log"
        echo "3) Hapus node"
        echo "5) Keluar"

        read -p "Masukkan pilihan Anda [1-3]: " choice

        case $choice in
            1)
                execute_script
                ;;
            2)
                view_logs
                ;;
            3)
                delete_node
                ;;
            5)
                echo "Keluar dari skrip."
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, silakan coba lagi."
                ;;
        esac
    done
}


# Fungsi menjalankan skrip
function execute_script() {
    # Periksa apakah pm2 sudah terinstal, jika tidak, instal secara otomatis
    if ! command -v pm2 &> /dev/null; then
        echo "pm2 belum terinstal, menginstal pm2..."
        sudo npm install -g pm2
        if [ $? -eq 0 ]; then
            echo "pm2 berhasil diinstal."
        else
            echo "Gagal menginstal pm2, periksa konfigurasi npm."
            exit 1
        fi
    else
        echo "pm2 sudah terinstal, lanjut eksekusi."
    fi

    # Periksa apakah tar sudah terinstal, jika tidak, instal secara otomatis
    if ! command -v tar &> /dev/null; then
        echo "tar belum terinstal, menginstal tar..."
        sudo apt-get update && sudo apt-get install -y tar
        if [ $? -eq 0 ]; then
            echo "tar berhasil diinstal."
        else
            echo "Gagal menginstal tar, periksa konfigurasi paket manajer."
            exit 1
        fi
    else
        echo "tar sudah terinstal, lanjut eksekusi."
    fi

    # Unduh versi terbaru executor
    echo "Mengunduh versi terbaru dari executor..."
    curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | \
    grep -Po '"tag_name": "\K.*?(?=")' | \
    xargs -I {} wget https://github.com/t3rn/executor-release/releases/download/{}/executor-linux-{}.tar.gz

    # Periksa apakah unduhan berhasil
    if [ $? -eq 0 ]; then
        echo "Unduhan berhasil."
    else
        echo "Unduhan gagal, periksa koneksi internet atau alamat unduhan."
        exit 1
    fi

    # Ekstrak file ke direktori saat ini
    echo "Mengekstrak file..."
    tar -xzf executor-linux-*.tar.gz

    # Periksa apakah ekstraksi berhasil
    if [ $? -eq 0 ]; then
        echo "Ekstraksi berhasil."
    else
        echo "Ekstraksi gagal, periksa file tar.gz."
        exit 1
    fi

    # Periksa apakah ada file atau direktori 'executor'
    echo "Memeriksa apakah file atau direktori 'executor' ditemukan..."
    if ls | grep -q 'executor'; then
        echo "Pemeriksaan berhasil, ditemukan file atau direktori 'executor'."
    else
        echo "Tidak ditemukan file atau direktori 'executor', periksa kembali."
        exit 1
    fi

    # Minta pengguna memasukkan nilai untuk gas price, default 100
    read -p "Masukkan nilai EXECUTOR_MAX_L3_GAS_PRICE [Default 100]: " EXECUTOR_MAX_L3_GAS_PRICE
    EXECUTOR_MAX_L3_GAS_PRICE="${EXECUTOR_MAX_L3_GAS_PRICE:-100}"

    # Atur variabel lingkungan
    export ENVIRONMENT=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,unichain-sepolia,optimism-sepolia,l2rn'
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
    export EXECUTOR_MAX_L3_GAS_PRICE="$EXECUTOR_MAX_L3_GAS_PRICE"

    # Variabel tambahan
    export EXECUTOR_PROCESS_BIDS_ENABLED=true
    export EXECUTOR_PROCESS_ORDERS_ENABLED=true
    export EXECUTOR_PROCESS_CLAIMS_ENABLED=true
    export RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
    "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
    "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
    "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
    }'

    # Minta pengguna memasukkan private key
    read -p "Masukkan PRIVATE_KEY_LOCAL: " PRIVATE_KEY_LOCAL

    # Atur private key sebagai variabel lingkungan
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    # Hapus file tar.gz setelah ekstraksi
    echo "Menghapus file arsip..."
    rm executor-linux-*.tar.gz

    # Pindah ke direktori executor/bin
    echo "Berpindah ke direktori executor/bin..."
    cd ~/executor/executor/bin

    # Jalankan executor menggunakan pm2
    echo "Menjalankan executor menggunakan pm2..."
    pm2 start ./executor --name "executor" --log "$LOGFILE" --env NODE_ENV=testnet

    # Tampilkan daftar proses pm2
    pm2 list

    echo "Executor berhasil dijalankan menggunakan pm2."

    # Tunggu input dari pengguna sebelum kembali ke menu utama
    read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali ke menu utama..."
    main_menu
}

# Fungsi melihat log
function view_logs() {
    if [ -f "$LOGFILE" ]; then
        echo "Menampilkan log secara real-time (Tekan Ctrl+C untuk keluar):"
        tail -f "$LOGFILE"
    else
        echo "Log tidak ditemukan."
    fi
}

# Fungsi menghapus node
function delete_node() {
    echo "Menghentikan proses node..."

    # Hentikan proses executor dengan pm2
    pm2 stop "executor"

    # Hapus direktori executor
    if [ -d "$EXECUTOR_DIR" ]; then
        echo "Menghapus direktori node..."
        rm -rf "$EXECUTOR_DIR"
        echo "Direktori node berhasil dihapus."
    else
        echo "Direktori node tidak ditemukan, mungkin sudah dihapus."
    fi

    echo "Node berhasil dihapus."

    # Tunggu input sebelum kembali ke menu utama
    read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali ke menu utama..."
    main_menu
}

# Jalankan menu utama
main_menu
