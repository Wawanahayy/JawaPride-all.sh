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
    echo "Instalasi Ritual Network dimulai..."

    sudo ufw allow ssh
    sudo ufw enable
    sudo ufw status

    # Cek apakah Docker sudah terinstal
    if ! command -v docker &> /dev/null; then
      echo "Docker tidak terinstal. Menginstal Docker..."
      sudo apt-get update
      sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io
      sudo docker run hello-world
    else
      echo "Docker sudah terinstal."
    fi

    # Cek apakah Docker Compose sudah terinstal
    if ! command -v docker-compose &> /dev/null; then
      echo "Docker Compose tidak terinstal. Menginstal Docker Compose..."
      sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
      mkdir -p $DOCKER_CONFIG/cli-plugins
      curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
      chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
      docker compose version
      sudo usermod -aG docker $USER
      docker run hello-world
    else
      echo "Docker Compose sudah terinstal."
    fi

    # Memastikan git terinstal
    if ! command -v git &> /dev/null; then
      echo "Git tidak terinstal. Menginstal Git..."
      sudo apt update
      sudo apt install git -y
    else
      echo "Git sudah terinstal."
    fi

    # Memastikan jq terinstal
    if ! command -v jq &> /dev/null; then
      echo "jq tidak terinstal. Menginstal jq..."
      sudo apt install jq -y
    else
      echo "jq sudah terinstal."
    fi

    # Memastikan lz4 terinstal
    if ! command -v lz4 &> /dev/null; then
      echo "lz4 tidak terinstal. Menginstal lz4..."
      sudo apt install lz4 -y
    else
      echo "lz4 sudah terinstal."
    fi

    # Memastikan screen terinstal
    if ! command -v screen &> /dev/null; then
      echo "screen tidak terinstal. Menginstal screen..."
      sudo apt install screen -y
    else
      echo "screen sudah terinstal."
    fi

    # Kloning repositori
    echo "Mengkloning repositori..."
    git clone https://github.com/ritual-net/infernet-container-starter
    cd infernet-container-starter

    # Membuat file konfigurasi
    echo "Membuat file konfigurasi..."

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
                "generates_proofs": false
            }
        ]
    }
EOL

    # Menyalin konfigurasi ke folder kontainer
    cp ~/infernet-container-starter/deploy/config.json ~/infernet-container-starter/projects/hello-world/container/config.json

    # Deploy kontainer menggunakan systemd
    echo "Membuat layanan systemd untuk Ritual Network..."
    cd ~/infernet-container-starter

    # Membuat script untuk dijalankan oleh systemd
    cat > ~/ritual-service.sh << EOL
    #!/bin/bash
    cd ~/infernet-container-starter
    echo "Memulai deployment kontainer pada \$(date)" > ~/ritual-deployment.log
    project=hello-world make deploy-container >> ~/ritual-deployment.log 2>&1
    echo "Deployment kontainer selesai pada \$(date)" >> ~/ritual-deployment.log

    # Memastikan kontainer tetap berjalan
    cd ~/infernet-container-starter
    while true; do
      echo "Memeriksa kontainer pada \$(date)" >> ~/ritual-deployment.log
      if ! docker ps | grep -q "infernet"; then
        echo "Kontainer berhenti. Menjalankan ulang pada \$(date)" >> ~/ritual-deployment.log
        docker compose -f deploy/docker-compose.yaml up -d >> ~/ritual-deployment.log 2>&1
      else
        echo "Kontainer berjalan dengan baik pada \$(date)" >> ~/ritual-deployment.log
      fi
      sleep 300
    done
EOL

    chmod +x ~/ritual-service.sh

    # Membuat file layanan systemd
    sudo tee /etc/systemd/system/ritual-network.service > /dev/null << EOL
    [Unit]
    Description=Ritual Network Infernet Service
    After=network.target docker.service
    Requires=docker.service

    [Service]
    Type=simple
    User=root
    ExecStart=/bin/bash /root/ritual-service.sh
    Restart=always
    RestartSec=30
    StandardOutput=append:/root/ritual-service.log
    StandardError=append:/root/ritual-service.log

    [Install]
    WantedBy=multi-user.target
EOL

    # Memuat ulang dan memulai layanan
    sudo systemctl daemon-reload
    sudo systemctl enable ritual-network.service
    sudo systemctl start ritual-network.service

    echo "Instalasi selesai! Layanan Ritual Network telah dimulai."
}

# Menampilkan log
view_logs() {
    tail -f ~/ritual-deployment.log
}

# Menghapus node Ritual
remove_ritual_node() {
    echo "Menghapus node Ritual Network..."

    sudo systemctl stop ritual-network.service
    sudo systemctl disable ritual-network.service

    # Menghapus konfigurasi dan kontainer
    sudo rm -rf ~/infernet-container-starter
    sudo rm -f /root/ritual-service.sh
    sudo rm -f /etc/systemd/system/ritual-network.service

    echo "Node Ritual Network telah dihapus."
}

# Menjalankan menu utama
main_menu
