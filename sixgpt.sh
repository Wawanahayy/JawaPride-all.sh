#!/bin/bash

# Menampilkan tampilan dari display.sh di menu utama
show_display() {
    echo "Menampilkan tampilan dari display.sh..."
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
}

# Fungsi untuk menginstal Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker belum terinstal, menginstal Docker..."
        sudo apt update -y
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update -y
        sudo apt install -y docker-ce
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "Docker berhasil diinstal!"
    else
        echo "Docker sudah terinstal, melewati instalasi."
    fi
}

# Fungsi untuk menginstal Docker Compose
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose belum terinstal, menginstal Docker Compose..."
        VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose berhasil diinstal!"
    else
        echo "Docker Compose sudah terinstal, melewati instalasi."
    fi
}

# Fungsi untuk membuat file .env
create_env() {
    echo "Masukkan VANA Private Key Anda: "
    read VANA_PRIVATE_KEY
    echo "Membuat file .env..."

    # Membuat file .env dengan nilai yang dimasukkan oleh pengguna
    cat <<EOL > .env
VANA_PRIVATE_KEY=$VANA_PRIVATE_KEY
VANA_NETWORK=moksha
OLLAMA_API_URL=http://ollama:11434/api
EOL

    echo ".env file berhasil dibuat!"
}


# Fungsi untuk menjalankan miner
run_miner() {
    echo "Menjalankan miner dengan Docker Compose..."
    docker-compose up -d
    echo "Miner berhasil dijalankan!"
}

# Fungsi untuk menampilkan log miner
view_logs() {
    echo "Menampilkan log miner..."
    docker-compose logs -f
}

# Fungsi untuk menghentikan miner
stop_miner() {
    echo "Menghentikan miner..."
    docker-compose down
    echo "Miner telah dihentikan."
}

# Fungsi untuk menghapus node
remove_node() {
    echo "Menghapus node..."
    docker ps -q | xargs -I {} docker rm -f {}
    echo "Node telah dihapus."
}

# Fungsi untuk menampilkan menu
show_menu() {
    clear
    show_display
    echo "==================== Menu ===================="
    echo "1) Install Docker"
    echo "2) Install Miner dan Docker Compose"
    echo "3) Lihat Logs Miner"
    echo "4) Keluar"
    echo "5) Hapus Node"
    echo "============================================="
    read -p "Pilih opsi [1-5]: " choice
    case $choice in
        1) install_docker; show_menu ;;
        2) install_docker_compose; create_env; run_miner; show_menu ;;
        3) view_logs; show_menu ;;
        4) exit 0 ;;
        5) remove_node; show_menu ;;
        *) echo "Pilihan tidak valid"; show_menu ;;
    esac
}

# Menampilkan menu utama
show_menu
