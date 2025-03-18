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


# Fungsi untuk menjalankan skrip
function execute_script() {
    # Periksa apakah pm2 sudah terinstal, jika tidak, instal otomatis
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
        echo "pm2 sudah terinstal, lanjut menjalankan skrip."
    fi

    # Unduh versi terbaru file
    echo "Mengunduh versi terbaru executor..."
    curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | \
    grep -Po '"tag_name": "\K.*?(?=")' | \
    xargs -I {} wget https://github.com/t3rn/executor-release/releases/download/{}/executor-linux-{}.tar.gz

    # Periksa apakah unduhan berhasil
    if [ $? -eq 0 ]; then
        echo "Unduhan berhasil."
    else
        echo "Unduhan gagal, periksa koneksi jaringan atau URL unduhan."
        exit 1
    fi

    # Ekstrak file ke direktori saat ini
    echo "Menjalankan ekstraksi file..."
    tar -xzf executor-linux-*.tar.gz

    # Periksa apakah ekstraksi berhasil
    if [ $? -eq 0 ]; then
        echo "Ekstraksi berhasil."
    else
        echo "Ekstraksi gagal, periksa file tar.gz."
        exit 1
    fi

    # Periksa apakah file hasil ekstraksi mengandung kata 'executor'
    echo "Memeriksa apakah file atau direktori hasil ekstraksi mengandung 'executor'..."
    if ls | grep -q 'executor'; then
        echo "File/direktori dengan 'executor' ditemukan."
    else
        echo "Tidak ditemukan file atau direktori dengan 'executor', kemungkinan nama file tidak sesuai."
        exit 1
    fi

    # Meminta pengguna memasukkan nilai variabel lingkungan
    read -p "Masukkan nilai EXECUTOR_MAX_L3_GAS_PRICE [default 100]: " EXECUTOR_MAX_L3_GAS_PRICE
    EXECUTOR_MAX_L3_GAS_PRICE="${EXECUTOR_MAX_L3_GAS_PRICE:-100}"

    # Mengatur variabel lingkungan
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

    # Meminta pengguna memasukkan private key
    read -p "Masukkan PRIVATE_KEY_LOCAL: " PRIVATE_KEY_LOCAL
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    # Menghapus file arsip
    echo "Menghapus file tar.gz..."
    rm executor-linux-*.tar.gz

    # Beralih ke direktori executor/bin
    echo "Beralih ke direktori dan memulai executor dengan pm2..."
    cd ~/executor/executor/bin

    # Menjalankan executor dengan pm2
    echo "Menjalankan executor dengan pm2..."
    pm2 start ./executor --name "executor" --log "$LOGFILE" --env NODE_ENV=testnet

    # Menampilkan daftar proses pm2
    pm2 list

    echo "executor telah dijalankan menggunakan pm2."

    # Tunggu input pengguna sebelum kembali ke menu utama
    read -n 1 -s -r -p "Tekan tombol apapun untuk kembali ke menu utama..."
    main_menu
}

# Fungsi untuk melihat log
function view_logs() {
    if [ -f "$LOGFILE" ]; then
        echo "Menampilkan log secara real-time (tekan Ctrl+C untuk keluar):"
        tail -f "$LOGFILE"  # Menggunakan tail -f untuk melihat log secara real-time
    else
        echo "File log tidak ditemukan."
    fi
}

# Fungsi untuk menghapus node
function delete_node() {
    echo "Menghentikan proses node..."

    # Menghentikan proses executor dengan pm2
    pm2 stop "executor"

    # Menghapus direktori executor
    if [ -d "$EXECUTOR_DIR" ]; then
        echo "Menghapus direktori node..."
        rm -rf "$EXECUTOR_DIR"
        echo "Direktori node telah dihapus."
    else
        echo "Direktori node tidak ditemukan, mungkin sudah dihapus sebelumnya."
    fi

    echo "Penghapusan node selesai."

    # Tunggu input pengguna sebelum kembali ke menu utama
    read -n 1 -s -r -p "Tekan tombol apapun untuk kembali ke menu utama..."
    main_menu
}

# Menjalankan menu utama
main_menu
