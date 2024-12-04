#!/bin/bash

# Path penyimpanan skrip
SCRIPT_PATH="$HOME/Vana-SixGPT.sh"

# Memeriksa apakah skrip dijalankan dengan pengguna root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan hak akses root."
    echo "Coba gunakan perintah 'sudo -i' untuk masuk sebagai root, lalu jalankan skrip ini lagi."
    exit 1
fi

# Fungsi menu utama
function main_menu() {
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
    while true; do
        clear
        echo "================================================================"
        echo "Untuk keluar dari skrip, tekan Ctrl + C pada keyboard."
        echo "Pilih tindakan yang ingin dilakukan:"
        echo "1) Jalankan node"
        echo "2) Lihat log"
        echo "3) Hapus node"
        echo "4) Keluar"
        
        read -p "Masukkan angka pilihan Anda: " choice
        
        case $choice in
            1)
                start_node
                ;;
            2)
                view_logs
                ;;
            3)
                delete_node
                ;;
            4)
                echo "Keluar dari skrip."
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, coba lagi."
                read -p "Tekan sembarang tombol untuk melanjutkan..."
                ;;
        esac
    done
}

# Fungsi untuk menjalankan node
function start_node() {
    # Memperbarui daftar paket dan meningkatkan paket yang terinstal
    sudo apt update -y && sudo apt upgrade -y

    # Menginstal dependensi yang diperlukan
    sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev tmux iptables curl nvme-cli git wget make jq libleveldb-dev \
    build-essential pkg-config ncdu tar clang bsdmainutils lsb-release \
    libssl-dev libreadline-dev libffi-dev jq gcc screen unzip lz4

    # Memeriksa apakah Docker sudah terinstal
    if ! command -v docker &> /dev/null; then
        echo "Docker belum terinstal, menginstal Docker..."
        
        # Instalasi Docker
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update -y
        sudo apt install -y docker-ce

        # Memulai layanan Docker
        sudo systemctl start docker
        sudo systemctl enable docker

        echo "Docker berhasil diinstal!"
    else
        echo "Docker sudah terinstal, melewati instalasi."
    fi

    # Memeriksa apakah Docker Compose sudah terinstal
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose belum terinstal, menginstal Docker Compose..."
        
        # Mendapatkan versi terbaru dan menginstal Docker Compose
        VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

        echo "Docker Compose berhasil diinstal!"
    else
        echo "Docker Compose sudah terinstal, melewati instalasi."
    fi

    # Menampilkan versi Docker Compose
    docker-compose --version

    # Menambahkan pengguna ke grup Docker
    if ! getent group docker > /dev/null; then
        echo "Membuat grup Docker..."
        sudo groupadd docker
    fi

    echo "Menambahkan pengguna $USER ke grup Docker..."
    sudo usermod -aG docker $USER

    # Membuat direktori dan mengatur variabel lingkungan
    mkdir -p ~/sixgpt
    cd ~/sixgpt

    # Meminta pengguna untuk memasukkan private key dan memilih jaringan
    read -p "Masukkan private key Anda (your_private_key): " PRIVATE_KEY
    export VANA_PRIVATE_KEY=$PRIVATE_KEY

    # Memilih jaringan
    echo "Pilih jaringan (masukkan angka 1):"
    echo "1) moksha"
    read -p "Masukkan angka pilihan Anda: " NETWORK_CHOICE

    case $NETWORK_CHOICE in
        1)
            export VANA_NETWORK="moksha"
            ;;
        *)
            echo "Pilihan tidak valid, memilih moksha secara default."
            export VANA_NETWORK="moksha"
            ;;
    esac

    echo "Jaringan yang dipilih: $VANA_NETWORK"

    # Membuat file docker-compose.yml
    cat <<EOL > docker-compose.yml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:0.3.12
    ports:
      - "11439:11434"
    volumes:
      - ollama:/root/.ollama
    restart: "unless-stopped"
 
  sixgpt3:
    image: sixgpt/miner:latest
    ports:
      - "3080:3000"
    depends_on:
      - ollama
    environment:
      - VANA_PRIVATE_KEY=${VANA_PRIVATE_KEY}
      - VANA_NETWORK=${VANA_NETWORK}
      - OLLAMA_API_URL=http://ollama:11434/api
    restart: "no"

volumes:
  ollama:
EOL

    # Memulai Docker Compose
    echo "Memulai Docker Compose..."
    docker-compose up -d
    echo "Docker Compose berhasil dijalankan!"
    echo "Semua operasi selesai! Silakan login ulang untuk menerapkan perubahan grup."

    read -p "Tekan sembarang tombol untuk kembali ke menu utama..."
}

# Fungsi untuk melihat log
function view_logs() {
    echo "Melihat log Docker Compose..."
    docker logs -f sixgpt_ollama_1
    read -p "Tekan sembarang tombol untuk kembali ke menu utama..."
}

# Fungsi untuk menghapus node
function delete_node() {
    echo "Masuk ke direktori /root/sixgpt..."
    cd /root/sixgpt || { echo "Direktori tidak ditemukan!"; return; }

    echo "Menghentikan semua layanan Docker Compose..."
    docker-compose down
    echo "Semua layanan Docker Compose telah dihentikan!"
    
    read -p "Tekan sembarang tombol untuk kembali ke menu utama..."
}

# Memanggil fungsi menu utama
main_menu
