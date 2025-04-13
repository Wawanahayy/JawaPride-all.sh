#!/bin/bash

# Periksa apakah skrip dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan hak akses root."
    echo "Silakan gunakan 'sudo -i' untuk masuk sebagai root, lalu jalankan kembali skrip ini."
    exit 1
fi

# Fungsi teks berwarna
printf_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

display_colored_text() {
    printf_colored "40;96" "============================================================"
    printf_colored "42;37" "=======================  J.W.P.A  =========================="
    printf_colored "45;97" "================= @AirdropJP_JawaPride ====================="
    printf_colored "43;30" "=============== https://x.com/JAWAPRIDE_ID ================="
    printf_colored "41;97" "============= https://linktr.ee/Jawa_Pride_ID =============="
    printf_colored "44;30" "============================================================"
}

# Menu utama
main_menu() {
    while true; do
        clear
        display_colored_text
        echo "Skrip ini gratis dan open-source. Jangan percaya jika ada yang meminta bayaran."
        echo "================================================================"
        echo "Tekan Ctrl + C untuk keluar."
        echo "Pilih operasi yang ingin dilakukan:"
        echo "1. Instal Node Ritual"
        echo "2. Lihat log Node Ritual"
        echo "3. Hapus Node Ritual"
        echo "4. Keluar dari skrip"

        read -p "Masukkan pilihan Anda: " choice

        case $choice in
            1) install_ritual_node ;;
            2) view_logs ;;
            3) remove_ritual_node ;;
            4) echo "Keluar dari skrip!"; exit 0 ;;
            *) echo "Pilihan tidak valid, silakan pilih lagi." ;;
        esac

        read -n 1 -s -p "Tekan tombol apa saja untuk melanjutkan..."
    done
}

install_ritual_node() {
    echo "Memulai instalasi Node Ritual..."

    apt update && apt install -y ufw curl git jq lz4 screen

    ufw allow ssh
    ufw --force enable

    # Install Docker jika belum ada
    if ! command -v docker &> /dev/null; then
        echo "Menginstal Docker..."
        curl -fsSL https://get.docker.com | bash
    fi

    # Install Docker Compose (modern)
    if ! docker compose version &> /dev/null; then
        echo "Menginstal Docker Compose plugin..."
        apt install -y docker-compose-plugin
    fi

    # Clone repo
    cd ~
    if [ -d "infernet-container-starter" ]; then
        echo "Folder sudah ada. Menghapus dan meng-clone ulang..."
        rm -rf infernet-container-starter
    fi
    git clone https://github.com/ritual-net/infernet-container-starter
    cd infernet-container-starter

    # Input private key
    read -s -p "Masukkan Private Key Metamask Anda: " private_key
    echo
    private_key=$(echo "$private_key" | sed 's/^0x//')
    private_key="0x$private_key"

    cat > ~/infernet-container-starter/deploy/config.json <<EOL
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
            "private_key": "$private_key",
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

    cp deploy/config.json projects/hello-world/container/config.json

    echo "Membuat service systemd..."

    cat > /etc/systemd/system/ritual-node.service <<EOL
[Unit]
Description=Ritual Infernet Node
After=network.target

[Service]
User=root
WorkingDirectory=/root/infernet-container-starter
ExecStart=/usr/bin/make deploy-container project=hello-world
Restart=always
RestartSec=10
StandardOutput=append:/root/ritual-deployment.log
StandardError=append:/root/ritual-deployment.log

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable ritual-node
    systemctl start ritual-node

    echo "Node Ritual berhasil dipasang dan dijalankan via systemd!"
}

view_logs() {
    journalctl -u ritual-node -f
}

remove_ritual_node() {
    echo "Menghapus Node Ritual..."
    systemctl stop ritual-node
    systemctl disable ritual-node
    rm /etc/systemd/system/ritual-node.service
    systemctl daemon-reload
    docker rm -f $(docker ps -aq)
    rm -rf ~/infernet-container-starter ~/ritual-deployment.log
    echo "Node Ritual berhasil dihapus."
}

main_menu
