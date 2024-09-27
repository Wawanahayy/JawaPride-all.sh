#!/bin/bash

# Memeriksa apakah skrip dijalankan sebagai pengguna root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini memerlukan hak akses sebagai pengguna root."
    echo "Silakan coba menggunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan skrip ini lagi."
    exit 1
fi

# Memeriksa dan menginstal Node.js dan npm
function install_nodejs_and_npm() {
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
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 sudah terinstal"
    else
        echo "PM2 belum terinstal, sedang menginstal..."
        npm install pm2@latest -g
    fi
}

# Fungsi instalasi node
function install_node() {
    install_nodejs_and_npm
    install_pm2

    pip3 install pillow
    pip3 install ddddocr
    pip3 install requests
    pip3 install loguru

    # Mengambil nama pengguna
    read -r -p "Masukkan email: " DAWNUSERNAME
    export DAWNUSERNAME=$DAWNUSERNAME

    # Mengambil kata sandi
    read -r -p "Masukkan kata sandi: " DAWNPASSWORD
    export DAWNPASSWORD=$DAWNPASSWORD

    echo $DAWNUSERNAME:$DAWNPASSWORD > password.txt

    wget -O dawn.py https://raw.githubusercontent.com/b1n4he/DawnAuto/main/dawn.py
    # Memperbarui dan menginstal perangkat lunak yang diperlukan
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd

    pm2 start dawn.py
}

# Menu utama
function main_menu() {
    while true; do
        clear
        cat << EOF
_________________________
< Skrip Otomatis Dawn (Versi VPS luar negeri), dari Twitter Kera @oxbaboon >
< Gratis dan sumber terbuka, siapa yang mengenakan biaya silakan langsung tanyakan >
-------------------------
        \   ^__^
        \  (oo)\_______
            (__)\       )\/\/
                ||----w |
                ||     ||
EOF
        echo "Untuk keluar dari skrip, tekan ctrl c pada keyboard untuk keluar."
        echo "Silakan pilih tindakan yang ingin dijalankan:"
        echo "1. Instal node"
        read -p "Masukkan opsi: " OPTION

        case $OPTION in
        1) install_node ;;
        *) echo "Opsi tidak valid." ;;
        esac
        echo "Tekan sembarang tombol untuk kembali ke menu utama..."
        read -n 1
    done
}

# Menampilkan menu utama
main_menu
