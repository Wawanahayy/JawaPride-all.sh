#!/bin/bash

SCRIPT_PATH="$HOME/Blockmesh.sh"
LOG_FILE="$HOME/blockmesh/blockmesh.log"
BLOCKMESH_DIR="$HOME/blockmesh"
BLOCKMESH_CLI_PATH="$BLOCKMESH_DIR/target/x86_64-unknown-linux-gnu/release/blockmesh-cli"
BLOCKMESH_TAR_URL="https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.412/block-mesh-manager-api-x86_64-unknown-linux-gnu.tar.gz"
BLOCKMESH_TAR_PATH="$BLOCKMESH_DIR/blockmesh-cli.tar.gz"

exec > >(tee -a "$LOG_FILE") 2>&1

# Fungsi untuk mencetak teks berwarna
print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\\e[${color_code}m${text}\\e[0m"
}

# Fungsi untuk menampilkan teks warna di header
display_colored_text() {
    print_colored "40;96" "============================================================"
    print_colored "42;37" "======================= J.W.P.A =========================="
    print_colored "45;97" "================= @AirdropJP_JawaPride ====================="
    print_colored "43;30" "=============== https://x.com/JAWAPRIDE_ID ================="
    print_colored "41;97" "============= https://linktr.ee/Jawa_Pride_ID =============="
    print_colored "44;30" "============================================================"
}

# Fungsi untuk menampilkan timestamp
print_timestamp() {
    local now=$(date -u +"%Y-%m-%d %H:%M:%S")
    local timezone_offset="+07:00"
    local adjusted_time=$(date -d "$now$timezone_offset" +"%Y-%m-%d %H:%M:%S")
    echo "Waktu saat ini (GMT+7): $adjusted_time"
}

# Fungsi untuk menu utama
function main_menu() {
    while true; do
        clear
        display_colored_text
        print_timestamp
        echo "============================================================"
        echo "USE screen -S blockmesh + TO EXIT CTRL A + D."
        echo "TO back screen screen -r blockmesh."
        echo "Welcome to Script with Jawa_Pride_ID:"
        echo "============================================================"
        echo "1. INSTALL OR LOGIN"
        echo "2. CHECK Logs"
        echo "3. CLOSE / Exit"
        read -p "Masukkan opsi (1-3): " option
        case $option in
            1) deploy_node ;;
            2) view_logs ;;
            3) echo "Keluar dari skrip." exit 0 ;;
            *) echo "Opsi tidak valid, silakan masukkan lagi."
               read -p "Tekan sembarang tombol untuk melanjutkan..." ;;
        esac
    done
}

# Fungsi untuk instalasi dan login Blockmesh
function deploy_node() {
    echo "Sedang memperbarui sistem..."
    sudo apt update -y && sudo apt upgrade -y

    if [ -d "$BLOCKMESH_DIR" ]; then
        echo "Direktori $BLOCKMESH_DIR sudah ada, sedang menghapusnya..."
        rm -rf "$BLOCKMESH_DIR"
    fi
    mkdir -p "$BLOCKMESH_DIR"
    echo "Direktori dibuat: $BLOCKMESH_DIR"

    # Mengunduh blockmesh-cli versi terbaru
    echo "Mengunduh blockmesh-cli versi 0.0.412..."
    curl -L "$BLOCKMESH_TAR_URL" -o "$BLOCKMESH_TAR_PATH"

    # Verifikasi file
    if [ ! -f "$BLOCKMESH_TAR_PATH" ]; then
        echo "Error: File blockmesh-cli.tar.gz tidak ditemukan setelah unduhan."
        exit 1
    fi

    # Verifikasi apakah file dalam format tar.gz
    if file "$BLOCKMESH_TAR_PATH" | grep -q 'gzip compressed data'; then
        echo "File valid, melanjutkan ekstraksi..."
    else
        echo "Error: File blockmesh-cli.tar.gz bukan format gzip yang valid."
        exit 1
    fi

    # Ekstraksi blockmesh-cli
    echo "Ekstraksi blockmesh-cli..."
    tar -xzf "$BLOCKMESH_TAR_PATH" -C "$BLOCKMESH_DIR"
    rm "$BLOCKMESH_TAR_PATH" # Hapus file .tar.gz setelah ekstraksi selesai
    echo "Unduhan dan ekstraksi blockmesh-cli selesai."
    echo "Path blockmesh-cli: $BLOCKMESH_CLI_PATH"

    read -p "Masukkan email BlockMesh Anda: " BLOCKMESH_EMAIL
    read -sp "Masukkan kata sandi BlockMesh Anda: " BLOCKMESH_PASSWORD
    echo
    export BLOCKMESH_EMAIL
    export BLOCKMESH_PASSWORD

    if [ ! -f "$BLOCKMESH_CLI_PATH" ]; then
        echo "Error: file blockmesh-cli tidak ditemukan, periksa unduhan dan ekstraksi."
        exit 1
    fi

    chmod +x "$BLOCKMESH_CLI_PATH"
    echo "Berpindah direktori dan menjalankan ./blockmesh-cli..."
    cd "$BLOCKMESH_DIR/target/x86_64-unknown-linux-gnu/release"
    echo "Memulai blockmesh-cli..."
    ./blockmesh-cli --email "$BLOCKMESH_EMAIL" --password "$BLOCKMESH_PASSWORD" > "$LOG_FILE" 2>&1 &
    echo "Eksekusi skrip selesai."
    read -p "Tekan sembarang tombol untuk kembali ke menu utama / click any tombol or ENTER..."
}

# Fungsi untuk melihat log
function view_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo "Menampilkan isi log:"
        cat "$LOG_FILE"
    else
        echo "File log tidak ditemukan: $LOG_FILE"
    fi
    read -p "Tekan sembarang tombol untuk kembali ke menu utama / click any tombol or ENTER..."
}

# Jalankan menu utama
main_menu
