#!/bin/bash

SCRIPT_PATH="$HOME/Blockmesh.sh"
LOG_FILE="$HOME/blockmesh/blockmesh.log"

exec > >(tee -a "$LOG_FILE") 2>&1

if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan hak akses root."
    echo "Coba gunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan skrip ini lagi."
    exit 1
fi

print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\e[${color_code}m${text}\e[0m"
}

display_colored_text() {
    print_colored "40;96" "============================================================"
    print_colored "42;37" "=======================  J.W.P.A  =========================="
    print_colored "45;97" "================= @AirdropJP_JawaPride ====================="
    print_colored "43;30" "=============== https://x.com/JAWAPRIDE_ID ================="
    print_colored "41;97" "============= https://linktr.ee/Jawa_Pride_ID =============="
    print_colored "44;30" "============================================================"
}

print_timestamp() {
    local now=$(date -u +"%Y-%m-%d %H:%M:%S")
    local timezone_offset="+07:00"
    local adjusted_time=$(date -d "$now$timezone_offset" +"%Y-%m-%d %H:%M:%S")
    echo "Waktu saat ini (GMT+7): $adjusted_time"
}

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

function deploy_node() {
    echo "Sedang memperbarui sistem..."
    sudo apt update -y && sudo apt upgrade -y

    BLOCKMESH_DIR="$HOME/blockmesh"
    LOG_FILE="$BLOCKMESH_DIR/blockmesh.log"

    if [ -d "$BLOCKMESH_DIR" ]; then
        echo "Direktori $BLOCKMESH_DIR sudah ada, sedang menghapusnya..."
        rm -rf "$BLOCKMESH_DIR"
    fi

    mkdir -p "$BLOCKMESH_DIR"
    echo "Direktori dibuat: $BLOCKMESH_DIR"

    echo "Mengunduh blockmesh-cli..."
    curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.325/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
    tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release"

    echo "Ekstraksi blockmesh-cli..."
    tar -xzf "$BLOCKMESH_DIR/blockmesh-cli.tar.gz" -C "$BLOCKMESH_DIR"
    rm "$BLOCKMESH_DIR/blockmesh-cli.tar.gz"
    echo "Unduhan dan ekstraksi blockmesh-cli selesai."

    BLOCKMESH_CLI_PATH="$BLOCKMESH_DIR/target/x86_64-unknown-linux-gnu/release/blockmesh-cli"
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
    cd /root/blockmesh/target/x86_64-unknown-linux-gnu/release

    echo "Memulai blockmesh-cli..."
    ./blockmesh-cli --email "$BLOCKMESH_EMAIL" --password "$BLOCKMESH_PASSWORD" > "$LOG_FILE" 2>&1 &
    echo "Eksekusi skrip selesai."

    read -p "Tekan sembarang tombol untuk kembali ke menu utama / click any tombol or ENTER..."
}

function view_logs() {
    LOG_FILE="/root/blockmesh/blockmesh.log"
    if [ -f "$LOG_FILE" ]; then
        echo "Menampilkan isi log:"
        cat "$LOG_FILE"
    else
        echo "File log tidak ditemukan: $LOG_FILE"
    fi
    read -p "Tekan sembarang tombol untuk kembali ke menu utama / click any tombol or ENTER..."
}

main_menu
