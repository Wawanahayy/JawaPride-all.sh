#!/bin/bash

print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\e[${color_code}m${text}\e[0m"
}

display_colored_text() {
    local colors=("40;96" "42;37" "45;97" "43;30" "41;97" "44;30")  # Daftar kode warna
    local blink_duration=5  # Durasi total perubahan warna dalam detik
    local end_time=$((SECONDS + blink_duration))
    
    while [ $SECONDS -lt $end_time ]; do
        for color in "${colors[@]}"; do
            print_colored "$color" "============================================================"
            print_colored "$color" "=======================  J.W.P.A  =========================="
            print_colored "$color" "================= @AirdropJP_JawaPride ====================="
            print_colored "$color" "=============== https://x.com/JAWAPRIDE_ID ================="
            print_colored "$color" "============= https://linktr.ee/Jawa_Pride_ID =============="
            print_colored "$color" "============================================================"
            
            # Menampilkan timestamp
            local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
            print_colored "$color" "Timestamp: $timestamp"

            sleep 0.5  # Delay sebelum mengganti warna
            clear  # Menghapus tampilan untuk efek perubahan warna
        done
    done
}

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        display_colored_text  # Menampilkan teks berwarna

        echo "================================================================"
        echo "Untuk keluar dari skrip, tekan ctrl + C di keyboard."
        echo "Pilih operasi yang ingin dilakukan:"
        echo "1. Deploy Node"
        echo "2. Lihat Log"
        echo "3. Keluar"

        read -p "Masukkan opsi (1-3): " option

        case $option in
            1)
                deploy_node
                ;;
            2)
                view_logs
                ;;
            3)
                echo "Keluar dari skrip."
                exit 0
                ;;
            *)
                echo "Opsi tidak valid, silakan masukkan lagi."
                read -p "Tekan sembarang tombol untuk melanjutkan..."
                ;;
        esac
    done
}

# Fungsi untuk deploy node
function deploy_node() {
    echo "Sedang memperbarui sistem..."
    sudo apt update -y && sudo apt upgrade -y

    # Membuat direktori blockmesh
    BLOCKMESH_DIR="$HOME/blockmesh"
    LOG_FILE="$BLOCKMESH_DIR/blockmesh.log"

    # Memeriksa apakah direktori blockmesh ada
    if [ -d "$BLOCKMESH_DIR" ]; then
        echo "Direktori $BLOCKMESH_DIR sudah ada, sedang menghapusnya..."
        rm -rf "$BLOCKMESH_DIR"
    fi

    # Membuat direktori blockmesh baru
    mkdir -p "$BLOCKMESH_DIR"
    echo "Direktori dibuat: $BLOCKMESH_DIR"

    # Mengunduh blockmesh-cli
    echo "Mengunduh blockmesh-cli..."
    curl -L "https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.324/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz" -o "$BLOCKMESH_DIR/blockmesh-cli.tar.gz"

    # Ekstrak dan hapus arsip
    echo "Ekstraksi blockmesh-cli..."
    tar -xzf "$BLOCKMESH_DIR/blockmesh-cli.tar.gz" -C "$BLOCKMESH_DIR"
    rm "$BLOCKMESH_DIR/blockmesh-cli.tar.gz"
    echo "Unduhan dan ekstraksi blockmesh-cli selesai."

    # Menentukan path blockmesh-cli
    BLOCKMESH_CLI_PATH="$BLOCKMESH_DIR/target/x86_64-unknown-linux-gnu/release/blockmesh-cli"
    echo "Path blockmesh-cli: $BLOCKMESH_CLI_PATH"

    # Meminta input email dan kata sandi BlockMesh dari pengguna
    read -p "Masukkan email BlockMesh Anda: " BLOCKMESH_EMAIL
    read -sp "Masukkan kata sandi BlockMesh Anda: " BLOCKMESH_PASSWORD
    echo

    # Menetapkan variabel lingkungan untuk email dan kata sandi BlockMesh
    export BLOCKMESH_EMAIL
    export BLOCKMESH_PASSWORD

    # Memeriksa apakah blockmesh-cli ada dan memiliki izin eksekusi
    if [ ! -f "$BLOCKMESH_CLI_PATH" ]; then
        echo "Error: file blockmesh-cli tidak ditemukan, periksa unduhan dan ekstraksi."
        exit 1
    fi

    chmod +x "$BLOCKMESH_CLI_PATH"  # Memastikan file dapat dieksekusi

    # Mengubah direktori dan menjalankan skrip
    echo "Berpindah direktori dan menjalankan ./blockmesh-cli..."
    cd /root/blockmesh/target/x86_64-unknown-linux-gnu/release

    # Menjalankan blockmesh-cli di direktori yang ditentukan
    echo "Memulai blockmesh-cli..."
    ./blockmesh-cli --email "$BLOCKMESH_EMAIL" --password "$BLOCKMESH_PASSWORD" > "$LOG_FILE" 2>&1 &
    echo "Eksekusi skrip selesai."

    # Menunggu input dari pengguna untuk melanjutkan
    read -p "Tekan sembarang tombol untuk kembali ke menu utama..."
}

# Fungsi untuk melihat log
function view_logs() {
    LOG_FILE="/root/blockmesh/blockmesh.log"  # Menggunakan path lengkap
    if [ -f "$LOG_FILE" ]; then
        echo "Menampilkan isi log:"
        cat "$LOG_FILE"  # Menampilkan isi log dengan perintah cat
    else
        echo "File log tidak ditemukan: $LOG_FILE"
    fi
    read -p "Tekan sembarang tombol untuk kembali ke menu utama..."
}

# Memulai menu utama
main_menu
