#!/bin/bash

# Periksa apakah skrip dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan hak akses root."
    echo "Silakan coba gunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan kembali skrip ini."
    exit 1
fi

# Fungsi untuk mencetak teks berwarna
printf_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

# Fungsi untuk menampilkan teks berwarna di bagian atas skrip
display_colored_text() {
    printf_colored "40;96" "============================================================"
    printf_colored "42;37" "=======================  J.W.P.A  =========================="
    printf_colored "45;97" "================= @AirdropJP_JawaPride ====================="
    printf_colored "43;30" "=============== https://x.com/JAWAPRIDE_ID ================="
    printf_colored "41;97" "============= https://linktr.ee/Jawa_Pride_ID =============="
    printf_colored "44;30" "============================================================"
}

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        display_colored_text
        echo "Skrip ini gratis dan open-source. Jangan percaya jika ada yang meminta bayaran."
        echo "================================================================"
        echo "Untuk keluar dari skrip, tekan Ctrl + C pada keyboard."
        echo "Silakan pilih operasi yang ingin dilakukan:"
        echo "1. Instal Node Ritual"
        echo "2. Lihat log Node Ritual"
        echo "3. Hapus Node Ritual"
        echo "4. Keluar dari skrip"

        read -p "Masukkan pilihan Anda: " choice

        case $choice in
            1) 
                install_ritual_node
                ;;
            2)
                view_logs
                ;;
            3)
                remove_ritual_node
                ;;
            4)
                echo "Keluar dari skrip!"
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, silakan pilih lagi."
                ;;
        esac

        echo "Tekan tombol apa saja untuk melanjutkan..."
        read -n 1 -s
    done
}

# Fungsi untuk menginstal node Ritual
install_ritual_node() {
    echo "Instalasi node Ritual Network dimulai..." | tee -a ~/ritual-install.log

    # Menginstal dependensi yang diperlukan
    echo "Menginstal dependensi..." | tee -a ~/ritual-install.log
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y docker.io docker-compose git jq lz4 screen

    # Mengecek apakah Docker sudah terpasang
    if ! command -v docker &> /dev/null; then
        echo "Docker tidak ditemukan, menginstal Docker..." | tee -a ~/ritual-install.log
        sudo apt install -y docker.io
    else
        echo "Docker sudah terpasang." | tee -a ~/ritual-install.log
    fi

    # Mengecek apakah Docker Compose sudah terpasang
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose tidak ditemukan, menginstal Docker Compose..." | tee -a ~/ritual-install.log
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "Docker Compose sudah terpasang." | tee -a ~/ritual-install.log
    fi

    # Meng-clone repository Ritual Network
    echo "Meng-clone repository Ritual Network..." | tee -a ~/ritual-install.log
    git clone https://github.com/ritual-net/infernet-container-starter
    cd infernet-container-starter

    # Membuat file konfigurasi
    echo "Membuat file konfigurasi..." | tee -a ~/ritual-install.log
    echo "Masukkan Private Key Metamask:"
    read -s private_key
    echo "Private key diterima (disembunyikan untuk keamanan)"

    # Menambahkan prefix 0x jika tidak ada
    if [[ ! $private_key =~ ^0x ]]; then
        private_key="0x$private_key"
        echo "Menambahkan prefix 0x pada private key"
    fi

    # Membuat file config.json dengan private key
    cat > ~/infernet-container-starter/deploy/config.json << EOL
{
    "log_path": "infernet_node.log",
    "server": {
        "port": 4000,
        "rate_limit": {
            "num_requests": 100,
            "period": 100
        }
    },
    "chain": {
        "enabled": true,
        "trail_head_blocks": 3,
        "rpc_url": "https://mainnet.base.org/",
        "registry_address": "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170",
        "wallet": {
          "max_gas_limit": 4000000,
          "private_key": "${private_key}",
          "allowed_sim_errors": []
        },
        "snapshot_sync": {
          "sleep": 3,
          "batch_size": 10000,
          "starting_sub_id": 180000,
          "sync_period": 30
        }
    },
    "startup_wait": 1.0,
    "redis": {
        "host": "redis",
        "port": 6379
    },
    "forward_stats": true,
    "containers": [
        {
            "id": "hello-world",
            "image": "ritualnetwork/hello-world-infernet:latest",
            "external": true,
            "port": "3000",
            "allowed_delegate_addresses": [],
            "allowed_addresses": [],
            "allowed_ips": [],
            "command": "--bind=0.0.0.0:3000 --workers=2",
            "env": {},
            "volumes": [],
            "accepted_payments": {},
            "generates_proofs": false
        }
    ]
}
EOL

    # Menyalin file konfigurasi ke folder container
    cp ~/infernet-container-starter/deploy/config.json ~/infernet-container-starter/projects/hello-world/container/config.json

    # Membuat layanan systemd untuk Ritual Network
    echo "Membuat layanan systemd untuk Ritual Network..." | tee -a ~/ritual-install.log
    sudo cp ~/infernet-container-starter/ritual-service.sh /root/ritual-service.sh
    sudo cp ~/infernet-container-starter/ritual-network.service /etc/systemd/system/ritual-network.service

    sudo systemctl daemon-reload
    sudo systemctl enable ritual-network.service
    sudo systemctl start ritual-network.service

    echo "Instalasi selesai! Layanan Ritual Network telah dimulai." | tee -a ~/ritual-install.log
}

# Fungsi untuk melihat log
view_logs() {
    tail -f ~/ritual-install.log
}

# Fungsi untuk menghapus node Ritual
remove_ritual_node() {
    echo "Menghapus node Ritual Network..." | tee -a ~/ritual-install.log

    sudo systemctl stop ritual-network.service
    sudo systemctl disable ritual-network.service

    # Menghapus konfigurasi dan kontainer
    sudo rm -rf ~/infernet-container-starter
    sudo rm -f /root/ritual-service.sh
    sudo rm -f /etc/systemd/system/ritual-network.service

    echo "Node Ritual Network telah dihapus." | tee -a ~/ritual-install.log
}

# Menjalankan menu utama
main_menu
