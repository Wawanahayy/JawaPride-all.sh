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

# Fungsi untuk menginstal Node Ritual
install_ritual_node() {
    echo "Instalasi Ritual Network dimulai..." | tee -a ~/ritual-install.log

    sudo ufw allow ssh
    sudo ufw enable
    sudo ufw status | tee -a ~/ritual-install.log

    # Cek apakah Docker sudah terinstal
    if ! command -v docker &> /dev/null; then
      echo "Docker tidak terinstal. Menginstal Docker..." | tee -a ~/ritual-install.log
      sudo apt-get update | tee -a ~/ritual-install.log
      sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release | tee -a ~/ritual-install.log
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg | tee -a ~/ritual-install.log
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null | tee -a ~/ritual-install.log
      sudo apt-get update | tee -a ~/ritual-install.log
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io | tee -a ~/ritual-install.log
      sudo docker run hello-world | tee -a ~/ritual-install.log
    else
      echo "Docker sudah terinstal." | tee -a ~/ritual-install.log
    fi

    # Cek apakah Docker Compose sudah terinstal
    if ! command -v docker-compose &> /dev/null; then
      echo "Docker Compose tidak terinstal. Menginstal Docker Compose..." | tee -a ~/ritual-install.log
      sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose | tee -a ~/ritual-install.log
      sudo chmod +x /usr/local/bin/docker-compose | tee -a ~/ritual-install.log
      DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
      mkdir -p $DOCKER_CONFIG/cli-plugins
      curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose | tee -a ~/ritual-install.log
      chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose | tee -a ~/ritual-install.log
      docker compose version | tee -a ~/ritual-install.log
      sudo usermod -aG docker $USER | tee -a ~/ritual-install.log
      docker run hello-world | tee -a ~/ritual-install.log
    else
      echo "Docker Compose sudah terinstal." | tee -a ~/ritual-install.log
    fi

    # Memastikan git terinstal
    if ! command -v git &> /dev/null; then
      echo "Git tidak terinstal. Menginstal Git..." | tee -a ~/ritual-install.log
      sudo apt update | tee -a ~/ritual-install.log
      sudo apt install git -y | tee -a ~/ritual-install.log
    else
      echo "Git sudah terinstal." | tee -a ~/ritual-install.log
    fi

    # Memastikan jq terinstal
    if ! command -v jq &> /dev/null; then
      echo "jq tidak terinstal. Menginstal jq..." | tee -a ~/ritual-install.log
      sudo apt install jq -y | tee -a ~/ritual-install.log
    else
      echo "jq sudah terinstal." | tee -a ~/ritual-install.log
    fi

    # Memastikan lz4 terinstal
    if ! command -v lz4 &> /dev/null; then
      echo "lz4 tidak terinstal. Menginstal lz4..." | tee -a ~/ritual-install.log
      sudo apt install lz4 -y | tee -a ~/ritual-install.log
    else
      echo "lz4 sudah terinstal." | tee -a ~/ritual-install.log
    fi

    # Memastikan screen terinstal
    if ! command -v screen &> /dev/null; then
      echo "screen tidak terinstal. Menginstal screen..." | tee -a ~/ritual-install.log
      sudo apt install screen -y | tee -a ~/ritual-install.log
    else
      echo "screen sudah terinstal." | tee -a ~/ritual-install.log
    fi

    # Kloning repositori
    echo "Mengkloning repositori..." | tee -a ~/ritual-install.log
    git clone https://github.com/ritual-net/infernet-container-starter | tee -a ~/ritual-install.log
    cd infernet-container-starter

    # Membuat file konfigurasi
    echo "Membuat file konfigurasi..." | tee -a ~/ritual-install.log

    # Meminta private key
    echo "Masukkan Private Key Metamask"
    read -s private_key
    echo "Private key diterima (tersembunyi untuk keamanan)"

    # Menambahkan prefix 0x jika hilang
    if [[ ! $private_key =~ ^0x ]]; then
      private_key="0x$private_key"
      echo "Menambahkan prefix 0x ke private key"
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
                "generous_spend": false,
                "monitoring": {}
            }
        ]
    }
    EOL

    # Menyiapkan systemd service
    echo "Menyiapkan layanan systemd..." | tee -a ~/ritual-install.log
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
