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
    printf_colored "42;30" "========================================================="
    printf_colored "46;30" "========================================================="
    printf_colored "45;97" "======================   T3RN   ========================="
    printf_colored "43;30" "============== create all by JAWA-PRIDE  ================"
    printf_colored "41;97" "=========== https://t.me/AirdropJP_JawaPride ============"
    printf_colored "44;30" "========================================================="
    printf_colored "42;97" "========================================================="
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


# Instal Node Ritual
function install_ritual_node() {
    echo "Memulai instalasi Node Ritual..."

    # Perbarui sistem dan instal paket dependensi
    echo "Memperbarui sistem..."
    sudo apt update && sudo apt upgrade -y

    echo "Menginstal paket yang diperlukan..."
    sudo apt -qy install curl git jq lz4 build-essential screen

    # Periksa apakah Docker dan Docker Compose sudah terinstal
    echo "Memeriksa apakah Docker sudah terinstal..."
    if ! command -v docker &> /dev/null
    then
        echo "Docker tidak terinstal, menginstal Docker..."
        sudo apt -qy install docker.io
    else
        echo "Docker sudah terinstal."
    fi

    echo "Memeriksa apakah Docker Compose sudah terinstal..."
    if ! command -v docker-compose &> /dev/null
    then
        echo "Docker Compose tidak terinstal, menginstal Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "Docker Compose sudah terinstal."
    fi

    # Clone repositori Git dan konfigurasi
    echo "Mengunduh repositori dari GitHub..."
    git clone https://github.com/ritual-net/infernet-container-starter ~/infernet-container-starter
    cd ~/infernet-container-starter

    # Meminta pengguna untuk memasukkan kunci pribadi secara tersembunyi
    echo "Masukkan kunci pribadi dompet Anda (tidak akan ditampilkan di layar):"
    read -s PRIVATE_KEY

    # Menulis konfigurasi ke file
    echo "Menulis file konfigurasi..."
    cat > deploy/config.json <<EOL
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
          "private_key": "$PRIVATE_KEY",
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

    echo "File konfigurasi berhasil ditulis!"

    # Instal Foundry
    echo "Menginstal Foundry..."
    mkdir -p ~/foundry && cd ~/foundry
    curl -L https://foundry.paradigm.xyz | bash

    # Memuat ulang variabel lingkungan
    source ~/.bashrc

    # Menunggu variabel lingkungan diterapkan
    echo "Menunggu variabel lingkungan Foundry diterapkan..."
    sleep 2

    # Verifikasi instalasi `foundryup`
    source ~/.bashrc
    foundryup
    if [ $? -ne 0 ]; then
        echo "Instalasi foundryup gagal, periksa kembali proses instalasi."
        exit 1
    fi

    echo "Foundry berhasil diinstal!"

    # Instal dependensi kontrak
    echo "Memasuki direktori contracts dan menginstal dependensi..."
    cd ~/infernet-container-starter/projects/hello-world/contracts

    # Menghapus direktori yang tidak valid jika ada
    rm -rf lib/forge-std
    rm -rf lib/infernet-sdk

    if ! command -v forge &> /dev/null
    then
        echo "Perintah forge tidak ditemukan, mencoba menginstal dependensi..."
        forge install --no-commit foundry-rs/forge-std
        forge install --no-commit ritual-net/infernet-sdk
    else
        echo "Forge sudah terinstal, menginstal dependensi..."
        forge install --no-commit foundry-rs/forge-std
        forge install --no-commit ritual-net/infernet-sdk
    fi
    echo "Dependensi berhasil diinstal!"

    # Menjalankan Docker Compose
    echo "Menjalankan Docker Compose..."
    cd ~/infernet-container-starter
    docker compose -f deploy/docker-compose.yaml up -d
    echo "Docker Compose berhasil dijalankan!"

    # Deploy kontrak
    echo "Mendeploy kontrak..."
    cd ~/infernet-container-starter
    project=hello-world make deploy-contracts
    echo "Kontrak berhasil dideploy!"

    echo "Node Ritual berhasil diinstal!"
}

# Lihat log Node Ritual
function view_logs() {
    echo "Menampilkan log Node Ritual..."
    docker logs -f infernet-node
}

# Hapus Node Ritual
function remove_ritual_node() {
    echo "Menghapus Node Ritual..."

    # Hentikan dan hapus kontainer Docker
    echo "Menghentikan dan menghapus kontainer Docker..."
    docker-compose -f ~/infernet-container-starter/deploy/docker-compose.yaml down

    # Hapus file repositori
    echo "Menghapus file terkait..."
    rm -rf ~/infernet-container-starter

    # Hapus image Docker
    echo "Menghapus image Docker..."
    docker rmi ritualnetwork/hello-world-infernet:latest

    echo "Node Ritual berhasil dihapus!"
}

# Menjalankan menu utama
main_menu
