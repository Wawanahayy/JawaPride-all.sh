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

install_ritual_node() {
    echo "Memulai instalasi Node Ritual..."

    # Mengaktifkan dan mengonfigurasi firewall
    sudo ufw allow ssh
    sudo ufw enable
    sudo ufw status

    # Memeriksa apakah Docker sudah terpasang
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
        echo "Docker berhasil diinstal."
    else
        echo "Docker sudah terpasang."
    fi

    # Memeriksa dan menginstal Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose tidak terpasang. Menginstal Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose berhasil diinstal."
    else
        echo "Docker Compose sudah terpasang."
    fi

    # Memeriksa dan menginstal Git
    if ! command -v git &> /dev/null; then
        echo "Git tidak terpasang. Menginstal Git..."
        sudo apt-get install -y git
        echo "Git berhasil diinstal."
    else
        echo "Git sudah terpasang."
    fi

    # Memeriksa dan menginstal jq
    if ! command -v jq &> /dev/null; then
        echo "jq tidak terpasang. Menginstal jq..."
        sudo apt-get install -y jq
        echo "jq berhasil diinstal."
    else
        echo "jq sudah terpasang."
    fi

    # Memeriksa dan menginstal lz4
    if ! command -v lz4 &> /dev/null; then
        echo "lz4 tidak terpasang. Menginstal lz4..."
        sudo apt-get install -y lz4
        echo "lz4 berhasil diinstal."
    else
        echo "lz4 sudah terpasang."
    fi

    # Memeriksa dan menginstal screen
    if ! command -v screen &> /dev/null; then
        echo "screen tidak terpasang. Menginstal screen..."
        sudo apt-get install -y screen
        echo "screen berhasil diinstal."
    else
        echo "screen sudah terpasang."
    fi

    # Meng-clone repository
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

    # Menyimpan private key dan konfigurasi ke file config.json
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
