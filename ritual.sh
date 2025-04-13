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

# Fungsi instalasi Node Ritual
install_ritual_node() {

    sudo ufw allow ssh
    sudo ufw enable
    sudo ufw status

    # Periksa apakah Docker sudah terpasang
    if ! command -v docker &> /dev/null; then
      echo "Docker tidak terpasang. Menginstal Docker..."
      sudo apt-get update
      sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io
      sudo docker run hello-world
    else
      echo "Docker sudah terpasang."
    fi

    # Periksa apakah Docker Compose sudah terpasang
    if ! command -v docker-compose &> /dev/null; then
      echo "Docker Compose tidak terpasang. Menginstal Docker Compose..."
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
      echo "Docker Compose sudah terpasang."
    fi

    # Periksa apakah git sudah terpasang
    if ! command -v git &> /dev/null; then
      echo "Git tidak terpasang. Menginstal Git..."
      sudo apt update
      sudo apt install git -y
    else
      echo "Git sudah terpasang."
    fi

    # Periksa apakah jq sudah terpasang
    if ! command -v jq &> /dev/null; then
      echo "jq tidak terpasang. Menginstal jq..."
      sudo apt install jq -y
    else
      echo "jq sudah terpasang."
    fi

    # Periksa apakah lz4 sudah terpasang
    if ! command -v lz4 &> /dev/null; then
      echo "lz4 tidak terpasang. Menginstal lz4..."
      sudo apt install lz4 -y
    else
      echo "lz4 sudah terpasang."
    fi

    # Install screen jika belum ada
    if ! command -v screen &> /dev/null; then
      echo "screen tidak terpasang. Menginstal screen..."
      sudo apt install screen -y
    else
      echo "screen sudah terpasang."
    fi

    # Clone Repository
    echo "Meng-clone repository..."
    git clone https://github.com/ritual-net/infernet-container-starter
    cd infernet-container-starter

    # Minta private key dan buat file konfigurasi
    echo "Masukkan Private Key Metamask:"
    read -s private_key
    echo "Private key diterima (tersembunyi untuk keamanan)"

    if [[ ! $private_key =~ ^0x ]]; then
      private_key="0x$private_key"
      echo "Menambahkan prefix 0x ke private key"
    fi

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

    # Salin konfigurasi ke folder container
    cp ~/infernet-container-starter/deploy/config.json ~/infernet-container-starter/projects/hello-world/container/config.json

    # Deploy container menggunakan systemd
    echo "Membuat systemd service untuk Ritual Network..."
    cd ~/infernet-container-starter

    cat > ~/ritual-service.sh << EOL
#!/bin/bash
cd ~/infernet-container-starter
echo "Mulai deploy container pada \$(date)" > ~/ritual-deployment.log
project=hello-world make deploy-container >> ~/ritual-deployment.log 2>&1
echo "Deploy container selesai pada \$(date)" >> ~/ritual-deployment.log

# Keep containers running
cd ~/infernet-container-starter
while true; do
  echo "Memeriksa container pada \$(date)" >> ~/ritual-deployment.log
  if ! docker ps | grep -q "infernet"; then
    echo "Container berhenti. Restarting pada \$(date)" >> ~/ritual-deployment.log
    docker compose -f deploy/docker-compose.yaml up -d >> ~/ritual-deployment.log 2>&1
  else
    echo "Container berjalan dengan normal pada \$(date)" >> ~/ritual-deployment.log
  fi
  sleep 300
done
EOL

    chmod +x ~/ritual-service.sh
    nohup bash ~/ritual-service.sh &
    echo "Node Ritual berhasil dipasang dan berjalan!"
}

# Fungsi melihat log
view_logs() {
    tail -f ~/infernet-container-starter/deploy/infernet-container-starter.log
}

# Fungsi menghapus Node Ritual
remove_ritual_node() {
    echo "Menghapus Node Ritual..."
    sudo docker stop infernet-container
    sudo docker rm infernet-container
    sudo rm -rf ~/infernet-container-starter
    echo "Node Ritual berhasil dihapus."
}

# Panggil menu utama
main_menu
