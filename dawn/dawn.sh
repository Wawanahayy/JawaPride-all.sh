#!/bin/bash

# Fungsi loading untuk menampilkan display
loading_step() {
    echo "Mengunduh dan menjalankan skrip display..."
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
    echo
}

# Jalur penyimpanan skrip
SCRIPT_PATH="$HOME/Dawn.sh"

# Memeriksa apakah skrip dijalankan sebagai pengguna root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini memerlukan hak akses pengguna root."
    echo "Silakan coba menggunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan skrip ini lagi."
    exit 1
fi

# Memeriksa dan menginstal Node.js dan npm
function install_nodejs_and_npm() {
    loading_step
    if command -v node > /dev/null 2>&1; then
        echo "Node.js sudah terinstal"
    else
        echo "Node.js belum terinstal, sedang menginstal..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm sudah terinstal"
    else
        echo "npm belum terinstal, sedang menginstal..."
        sudo apt-get install -y npm
    fi
}

# Memeriksa dan menginstal PM2
function install_pm2() {
    loading_step
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 sudah terinstal"
    else
        echo "PM2 belum terinstal, sedang menginstal..."
        npm install pm2@latest -g
    fi
}

# Menginstal alat manajemen paket Python pip3
function install_pip() {
    loading_step
    if ! command -v pip3 > /dev/null 2>&1; then
        echo "pip3 belum terinstal, sedang menginstal..."
        sudo apt-get install -y python3-pip
    else
        echo "pip3 sudah terinstal"
    fi
}

# Menginstal paket Python
function install_python_packages() {
    loading_step
    echo "Menginstal paket Python..."
    pip3 install pillow ddddocr requests loguru
}

# Fungsi untuk menginstal dan memulai Dawn
function install_and_start_dawn() {
    loading_step
    # Memperbarui dan menginstal perangkat lunak yang diperlukan
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip lz4 snapd

    # Menginstal Node.js dan npm, PM2, pip3, dan paket Python
    install_nodejs_and_npm
    install_pm2
    install_pip
    install_python_packages

    # Mendapatkan nama pengguna dan kata sandi
    read -r -p "Masukkan email: " DAWNUSERNAME
    export DAWNUSERNAME=$DAWNUSERNAME
    read -r -p "Masukkan kata sandi: " DAWNPASSWORD
    export DAWNPASSWORD=$DAWNPASSWORD

    echo "$DAWNUSERNAME:$DAWNPASSWORD" > password.txt

    # Mendapatkan informasi API Fast Captcha
    read -r -p "Masukkan kunci API Fast Captcha: " FAST_CAPTCHA_API_KEY
    echo "$FAST_CAPTCHA_API_KEY" > fast_captcha_api_key.txt

    wget -O dawn.py https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/dawn/dawn.py

    # Memulai Dawn
    pm2 start python3 --name dawn -- dawn.py
}

# Fungsi untuk melihat log
function view_logs() {
    loading_step
    echo "Melihat log Dawn..."
    pm2 log dawn
    # Menunggu pengguna menekan tombol apa saja untuk kembali ke menu utama
    read -p "Tekan tombol apa saja untuk kembali ke menu utama..."
}

# Fungsi untuk menghentikan dan menghapus Dawn
function stop_and_remove_dawn() {
    loading_step
    if pm2 list | grep -q "dawn"; then
        echo "Menghentikan Dawn..."
        pm2 stop dawn
        echo "Menghapus Dawn..."
        pm2 delete dawn
    else
        echo "Dawn tidak sedang berjalan"
    fi

    # Menunggu pengguna menekan tombol apa saja untuk kembali ke menu utama
    read -p "Tekan tombol apa saja untuk kembali ke menu utama..."
}

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        loading_step
        echo "Silakan pilih operasi yang ingin dilakukan:"
        echo "1) Instal dan mulai Dawn"
        echo "2) Lihat log"
        echo "3) Hentikan dan hapus Dawn"
        echo "4) Keluar"

        read -p "Masukkan pilihan [1-4]: " choice

        case $choice in
            1)
                install_and_start_dawn
                ;;
            2)
                view_logs
                ;;
            3)
                stop_and_remove_dawn
                ;;
            4)
                echo "Keluar dari skrip..."
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, silakan pilih lagi."
                read -n 1 -s -r -p "Tekan tombol apa saja untuk melanjutkan..."
                ;;
        esac
    done
}

# Menjalankan menu utama
main_menu
