#!/usr/bin/env bash

# Periksa apakah skrip dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan hak akses root."
    echo "Silakan coba gunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan kembali skrip ini."
    exit 1
fi

# Jalur penyimpanan skrip
SCRIPT_PATH="$HOME/Ritual.sh"

# Jalur file log
LOG_FILE="/root/ritual_install.log"
DOCKER_LOG_FILE="/root/infernet_node.log"

# Inisialisasi file log
echo "Log Skrip Ritual - $(date)" > "$LOG_FILE"
echo "Log Kontainer Docker - $(date)" > "$DOCKER_LOG_FILE"

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
    printf_colored "43;30" "============== dibuat oleh JAWA-PRIDE  ================"
    printf_colored "41;97" "=========== https://t.me/AirdropJP_JawaPride ==========="
    printf_colored "44;30" "========================================================="
    printf_colored "42;97" "========================================================="
}

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        display_colored_text
        echo "Skrip ini gratis dan open-source. Jangan percaya jika ada yang meminta bayaran." | tee -a "$LOG_FILE"
        echo "================================================================" | tee -a "$LOG_FILE"
        echo "Untuk keluar dari skrip, tekan Ctrl + C pada keyboard." | tee -a "$LOG_FILE"
        echo "Silakan pilih operasi yang ingin dilakukan:" | tee -a "$LOG_FILE"
        echo "1) Instalasi Node Ritual" | tee -a "$LOG_FILE"
        echo "2) Lihat Log Node Ritual" | tee -a "$LOG_FILE"
        echo "3) Hapus Node Ritual" | tee -a "$LOG_FILE"
        echo "4) Keluar dari Skrip" | tee -a "$LOG_FILE"

        read -p "Masukkan pilihan Anda: " choice
        echo "Pilihan pengguna: $choice" >> "$LOG_FILE"

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
                echo "Keluar dari skrip!" | tee -a "$LOG_FILE"
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, silakan coba lagi." | tee -a "$LOG_FILE"
                ;;
        esac

        echo "Tekan tombol apa saja untuk melanjutkan..." | tee -a "$LOG_FILE"
        read -n 1 -s
    done
}

# Fungsi instalasi node
function install_ritual_node() {
    echo "Memulai instalasi Node Ritual - $(date)" | tee -a "$LOG_FILE"
    sudo apt update && sudo apt upgrade -y >> "$LOG_FILE" 2>&1
    sudo apt -qy install curl git jq lz4 build-essential screen python3 python3-pip >> "$LOG_FILE" 2>&1

    pip3 install --upgrade pip >> "$LOG_FILE" 2>&1
    pip3 install infernet-cli infernet-client >> "$LOG_FILE" 2>&1

    if ! command -v docker &> /dev/null; then
        echo "Docker belum terinstal, menginstal..." | tee -a "$LOG_FILE"
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common >> "$LOG_FILE" 2>&1
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - >> "$LOG_FILE" 2>&1
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >> "$LOG_FILE" 2>&1
        sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io >> "$LOG_FILE" 2>&1
        sudo systemctl enable docker && sudo systemctl start docker >> "$LOG_FILE" 2>&1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo "Docker Compose belum terinstal, menginstal..." | tee -a "$LOG_FILE"
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
        sudo chmod +x /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
    fi

    echo "Menginstal Foundry..." | tee -a "$LOG_FILE"
    if pgrep anvil &>/dev/null; then
        echo "Menutup proses anvil agar dapat memperbarui Foundry..." | tee -a "$LOG_FILE"
        pkill anvil
        sleep 2
    fi
    mkdir -p ~/foundry && cd ~/foundry
    curl -L https://foundry.paradigm.xyz | bash >> "$LOG_FILE" 2>&1
    $HOME/.foundry/bin/foundryup >> "$LOG_FILE" 2>&1
    export PATH="$HOME/.foundry/bin:$PATH"
    forge --version >> "$LOG_FILE" 2>&1 || { echo "Forge tidak ditemukan." | tee -a "$LOG_FILE"; exit 1; }

    if [ -d "infernet-container-starter" ]; then
        echo "Direktori sudah ada, menghapus..." | tee -a "$LOG_FILE"
        rm -rf infernet-container-starter
    fi

    git clone https://github.com/ritual-net/infernet-container-starter >> "$LOG_FILE" 2>&1
    cd infernet-container-starter
    docker pull ritualnetwork/hello-world-infernet:latest >> "$LOG_FILE" 2>&1

    echo "Memulai screen session dan membuat log..." | tee -a "$LOG_FILE"
    screen -S ritual -L -Logfile /root/ritual_screen.log -dm bash -c 'project=hello-world make deploy-container; exec bash'

    read -p "Masukkan Private Key Anda (0x...): " PRIVATE_KEY
    echo "Private Key dimasukkan oleh pengguna." >> "$LOG_FILE"
    sed -i "s|\"private_key\": \".*\"|\"private_key\": \"$PRIVATE_KEY\"|" deploy/config.json

    docker compose -f deploy/docker-compose.yaml down >> "$LOG_FILE" 2>&1
    docker compose -f deploy/docker-compose.yaml up -d >> "$LOG_FILE" 2>&1
    docker logs -f infernet-node >> "$DOCKER_LOG_FILE" 2>&1 &

    echo "Instalasi dependensi proyek dengan forge..." | tee -a "$LOG_FILE"
    cd projects/hello-world/contracts || exit 1
    rm -rf lib/forge-std lib/infernet-sdk
    forge install --no-commit foundry-rs/forge-std >> "$LOG_FILE" 2>&1
    forge install --no-commit ritual-net/infernet-sdk >> "$LOG_FILE" 2>&1

    cd ~/infernet-container-starter || exit 1
    docker compose -f deploy/docker-compose.yaml down >> "$LOG_FILE" 2>&1
    docker compose -f deploy/docker-compose.yaml up -d >> "$LOG_FILE" 2>&1

    echo "Mendeploy kontrak..." | tee -a "$LOG_FILE"
    project=hello-world make deploy-contracts >> "$LOG_FILE" 2>&1
    echo "Selesai instalasi." | tee -a "$LOG_FILE"
}

function view_logs() {
    echo "Menampilkan log dari Node Ritual (tail realtime):" | tee -a "$LOG_FILE"
    tail -f "$DOCKER_LOG_FILE"
}

function remove_ritual_node() {
    echo "Menghapus Node Ritual..." | tee -a "$LOG_FILE"
    cd ~/infernet-container-starter || exit 1
    docker compose down >> "$LOG_FILE" 2>&1
    containers=("infernet-node" "infernet-fluentbit" "infernet-redis" "infernet-anvil" "hello-world")
    for container in "${containers[@]}"; do
        if docker ps -aq -f name=$container; then
            docker stop $container >> "$LOG_FILE" 2>&1
            docker rm $container >> "$LOG_FILE" 2>&1
        fi
    done
    rm -rf ~/infernet-container-starter >> "$LOG_FILE" 2>&1
    docker rmi -f ritualnetwork/hello-world-infernet:latest ritualnetwork/infernet-node:latest fluent/fluent-bit:3.1.4 redis:7.4.0 ritualnetwork/infernet-anvil:1.0.0 >> "$LOG_FILE" 2>&1
    echo "Node berhasil dihapus." | tee -a "$LOG_FILE"
}

# Jalankan menu utama
main_menu
