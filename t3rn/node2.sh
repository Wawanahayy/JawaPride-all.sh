#!/bin/bash

# Path penyimpanan skrip
SCRIPT_PATH="$HOME/t3rn.sh"
LOGFILE="$HOME/executor/executor.log"
EXECUTOR_DIR="$HOME/executor"

# Memeriksa apakah skrip dijalankan dengan hak akses root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini perlu dijalankan dengan hak akses root."
    echo "Silakan coba menggunakan perintah 'sudo -i' untuk beralih ke root, lalu jalankan skrip ini lagi."
    exit 1
fi

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        echo "Skrip ini dibuat oleh komunitas Dadu Besar Hahahaha, Twitter @ferdie_jhovie, gratis dan sumber terbuka, jangan percaya yang berbayar."
        echo "Jika ada masalah, bisa menghubungi Twitter, hanya ada satu akun ini."
        echo "================================================================"
        echo "Untuk keluar dari skrip, tekan ctrl + C pada keyboard."
        echo "Pilih tindakan yang ingin dilakukan:"
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
    # Memeriksa apakah pm2 terinstal, jika belum maka akan diinstal otomatis
    if ! command -v pm2 &> /dev/null; then
        echo "pm2 belum terinstal, sedang menginstal pm2..."
        # Menginstal pm2
        sudo npm install -g pm2
        if [ $? -eq 0 ]; then
            echo "pm2 berhasil diinstal."
        else
            echo "Instalasi pm2 gagal, periksa konfigurasi npm Anda."
            exit 1
        fi
    else
        echo "pm2 sudah terinstal, melanjutkan eksekusi."
    fi

    # Mengunduh file
    echo "Sedang mengunduh executor-linux-v0.32.0.tar.gz..."
    wget https://github.com/t3rn/executor-release/releases/download/v0.32.0/executor-linux-v0.32.0.tar.gz

    # Memeriksa apakah unduhan berhasil
    if [ $? -eq 0 ]; then
        echo "Unduhan berhasil."
    else
        echo "Unduhan gagal, periksa koneksi jaringan atau alamat unduhan."
        exit 1
    fi

    # Mengekstrak file ke direktori saat ini
    echo "Sedang mengekstrak file..."
    tar -xvzf executor-linux-v0.32.0.tar.gz

    # Memeriksa apakah ekstraksi berhasil
    if [ $? -eq 0 ]; then
        echo "Ekstraksi berhasil."
    else
        echo "Ekstraksi gagal, periksa file tar.gz."
        exit 1
    fi

    # Memeriksa apakah nama file yang diekstrak mengandung 'executor'
    echo "Memeriksa apakah nama file atau direktori yang diekstrak mengandung 'executor'..."
    if ls | grep -q 'executor'; then
        echo "Pemeriksaan berhasil, menemukan file atau direktori yang mengandung 'executor'."
    else
        echo "Tidak ditemukan file atau direktori yang mengandung 'executor', mungkin nama file salah."
        exit 1
    fi

    # Meminta pengguna memasukkan nilai untuk variabel lingkungan, menetapkan nilai default untuk EXECUTOR_MAX_L3_GAS_PRICE sebagai 100
    read -p "Masukkan nilai untuk EXECUTOR_MAX_L3_GAS_PRICE [default 100]: " EXECUTOR_MAX_L3_GAS_PRICE
    EXECUTOR_MAX_L3_GAS_PRICE="${EXECUTOR_MAX_L3_GAS_PRICE:-100}"

    # Meminta pengguna memasukkan nilai untuk RPC_ENDPOINTS_OPSP, jika tidak diisi maka menggunakan nilai default
    read -p "Masukkan nilai untuk RPC_ENDPOINTS_OPSP [default https://sepolia.optimism.io]: " RPC_ENDPOINTS_OPSP
    RPC_ENDPOINTS_OPSP="${RPC_ENDPOINTS_OPSP:-https://sepolia.optimism.io}"

    # Meminta pengguna memasukkan nilai untuk RPC_ENDPOINTS_BSSP, jika tidak diisi maka menggunakan nilai default
    read -p "Masukkan nilai untuk RPC_ENDPOINTS_BSSP [default https://sepolia.base.org]: " RPC_ENDPOINTS_BSSP
    RPC_ENDPOINTS_BSSP="${RPC_ENDPOINTS_BSSP:-https://sepolia.base.org}"

    # Meminta pengguna memasukkan nilai untuk RPC_ENDPOINTS_BLSS, jika tidak diisi maka menggunakan nilai default
    read -p "Masukkan nilai untuk RPC_ENDPOINTS_BLSS [default https://blessnet-sepolia-testnet.rpc.caldera.xyz/http]: " RPC_ENDPOINTS_BLSS
    RPC_ENDPOINTS_BLSS="${RPC_ENDPOINTS_BLSS:-https://blessnet-sepolia-testnet.rpc.caldera.xyz/http}"

    # Meminta pengguna memasukkan nilai untuk RPC_ENDPOINTS_ARBT, jika tidak diisi maka menggunakan nilai default
    read -p "Masukkan nilai untuk RPC_ENDPOINTS_ARBT [default https://endpoints.omniatech.io/v1/arbitrum/sepolia/public]: " RPC_ENDPOINTS_ARBT
    RPC_ENDPOINTS_ARBT="${RPC_ENDPOINTS_ARBT:-https://endpoints.omniatech.io/v1/arbitrum/sepolia/public}"

    # Menetapkan variabel lingkungan
    export NODE_ENV=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,l1rn'
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
    export EXECUTOR_MAX_L3_GAS_PRICE="$EXECUTOR_MAX_L3_GAS_PRICE"

    # Variabel lingkungan tambahan
    export EXECUTOR_PROCESS_ORDERS=true
    export EXECUTOR_PROCESS_CLAIMS=true
    export RPC_ENDPOINTS_OPSP="$RPC_ENDPOINTS_OPSP"
    export RPC_ENDPOINTS_BSSP="$RPC_ENDPOINTS_BSSP"
    export RPC_ENDPOINTS_BLSS="$RPC_ENDPOINTS_BLSS"
    export RPC_ENDPOINTS_ARBT="$RPC_ENDPOINTS_ARBT"

    # Meminta pengguna memasukkan private key
    read -p "Masukkan nilai PRIVATE_KEY_LOCAL: " PRIVATE_KEY_LOCAL

    # Menetapkan variabel private key
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    # Menghapus file arsip
    echo "Menghapus file arsip..."
    rm executor-linux-v0.29.0.tar.gz

    # Berpindah ke direktori executor/bin
    echo "Berpindah ke direktori dan menyiapkan pm2 untuk memulai executor..."
    cd ~/executor/executor/bin

    # Menggunakan pm2 untuk memulai executor
    echo "Memulai executor menggunakan pm2..."
    pm2 start ./executor --name "executor" --log "$LOGFILE" --env NODE_ENV=testnet

    # Menampilkan daftar proses pm2
    pm2 list

    echo "Executor telah dimulai menggunakan pm2."

    # Meminta pengguna menekan tombol apa saja untuk kembali ke menu utama
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu utama..."
    main_menu
}

# Fungsi untuk melihat log
function view_logs() {
    if [ -f "$LOGFILE" ]; then
        echo "Menampilkan log secara real-time (tekan Ctrl+C untuk keluar):"
        tail -f "$LOGFILE"  # Menggunakan tail -f untuk melacak log secara langsung
    else
        echo "File log tidak ditemukan."
    fi
}

# Fungsi untuk menghapus node
function delete_node() {
    echo "Sedang menghentikan proses node..."

    # Menggunakan pm2 untuk menghentikan proses executor
    pm2 stop "executor"

    # Menghapus direktori tempat executor berada
    if [ -d "$EXECUTOR_DIR" ]; then
        echo "Sedang menghapus direktori node..."
        rm -rf "$EXECUTOR_DIR"
        echo "Direktori node telah dihapus."
    else
        echo "Direktori node tidak ditemukan, mungkin sudah dihapus."
    fi

    echo "Operasi penghapusan node selesai."

    # Meminta pengguna menekan tombol apa saja untuk kembali ke menu utama
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu utama..."
    main_menu
}

# Memulai menu utama
main_menu
