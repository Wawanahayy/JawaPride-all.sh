#!/bin/bash

print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

display_colored_text() {
    print_colored "42;30" "========================================================="
    print_colored "46;30" "========================================================="
    print_colored "45;97" "======================   T3EN   ========================="
    print_colored "43;30" "============== modify all by JAWA-PRIDE  ================"
    print_colored "41;97" "=========== https://t.me/AirdropJP_JawaPride ============"
    print_colored "44;30" "========================================================="
    print_colored "42;97" "========================================================="
}

display_colored_text
sleep 5

log() {
    local level=$1
    local message=$2
    echo "[$level] $message"
}

# Pertanyaan untuk bergabung dengan channel
read -p "Apakah Anda sudah bergabung dengan channel kami Channel: @AirdropJP_JawaPride https://t.me/AirdropJP_JawaPride? (y/n): " join_channel

if [[ "$join_channel" == "y" || "$join_channel" == "Y" ]]; then
    echo "Terima kasih telah bergabung dengan channel kami!"
else
    echo "Telegram @AirdropJP_JawaPride"
    sleep 5
    exit 1
fi

# Mengunduh dan menjalankan skrip dari URL
curl -s https://github.com/Wawanahayy/JP/blob/main/t3rn-executor.sh | bash
sleep 5

echo "T3rn Executor!"

remove_old_service() {
    echo "Menghentikan dan menghapus service lama jika ada..."
    sudo systemctl stop executor.service 2>/dev/null
    sudo systemctl disable executor.service 2>/dev/null
    sudo rm -f /etc/systemd/system/executor.service
    sudo systemctl daemon-reload
    echo "Service lama telah dihapus."
}

update_system() {
    echo "Memperbarui dan meng-upgrade sistem..."
    sudo apt update -q && sudo apt upgrade -qy
    if [ $? -ne 0 ]; then
        echo "Update sistem gagal. Keluar."
        exit 1
    fi
}

download_and_extract_binary() {
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep 'tag_name' | cut -d\" -f4)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/executor-linux-${LATEST_VERSION}.tar.gz"
    EXECUTOR_FILE="executor-linux-${LATEST_VERSION}.tar.gz"

    echo "Versi terbaru terdeteksi: $LATEST_VERSION"
    echo "Mengunduh binary Executor dari $EXECUTOR_URL..."
    curl -L -o $EXECUTOR_FILE $EXECUTOR_URL

    if [ $? -ne 0 ]; then
        echo "Gagal mengunduh binary Executor. Periksa koneksi internet Anda dan coba lagi."
        exit 1
    fi

    echo "Mengekstrak binary..."
    tar -xzvf $EXECUTOR_FILE
    if [ $? -ne 0 ]; then
        echo "Ekstraksi gagal. Keluar."
        exit 1
    fi

    rm -rf $EXECUTOR_FILE
    cd executor/executor/bin || exit
    echo "Binary berhasil diunduh dan diekstrak."
}

set_environment_variables() {
    export NODE_ENV=testnet
    export LOG_LEVEL=info
    export LOG_PRETTY=false
    echo "Variabel lingkungan disetel: NODE_ENV=$NODE_ENV, LOG_LEVEL=$LOG_LEVEL, LOG_PRETTY=$LOG_PRETTY"
}

set_private_key() {
    while true; do
        read -p "Masukkan Private Key Metamask Anda (tanpa prefix 0x): " PRIVATE_KEY_LOCAL
        PRIVATE_KEY_LOCAL=${PRIVATE_KEY_LOCAL#0x}

        if [ ${#PRIVATE_KEY_LOCAL} -eq 64 ]; then
            export PRIVATE_KEY_LOCAL
            echo "Private key telah disetel."
            break
        else
            echo "Private key tidak valid. Harus 64 karakter panjangnya (tanpa prefix 0x)."
        fi
    done
}

set_enabled_networks() {
    read -p "Apakah Anda ingin mengaktifkan 5 jaringan default (arbitrum-sepolia, base-sepolia, blast-sepolia, optimism-sepolia, l1rn)? (y/n): " aktifkan_lima

    if [[ "$aktifkan_lima" == "y" || "$aktifkan_lima" == "Y" ]]; then
        ENABLED_NETWORKS="arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,l1rn"
        echo "Mengaktifkan 5 jaringan default: $ENABLED_NETWORKS"
    else
        echo "Anda tidak memilih untuk mengaktifkan 5 jaringan default."
        exit 0
    fi

    echo "Pengaturan selesai. Jaringan yang diaktifkan: $ENABLED_NETWORKS"
}

create_systemd_service() {
    SERVICE_FILE="/etc/systemd/system/executor.service"
    sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Executor Service
After=network.target

[Service]
User=root
WorkingDirectory=/root/executor/executor
Environment="NODE_ENV=testnet"
Environment="LOG_LEVEL=info"
Environment="LOG_PRETTY=false"
Environment="PRIVATE_KEY_LOCAL=0x$PRIVATE_KEY_LOCAL"
Environment="ENABLED_NETWORKS=$ENABLED_NETWORKS"
ExecStart=/root/executor/executor/bin/executor
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOL
}

start_service() {
    sudo systemctl daemon-reload
    sudo systemctl enable executor.service
    sudo systemctl start executor.service
    echo "Setup selesai! Service Executor telah dibuat dan dijalankan."
    echo "Anda dapat memeriksa status service menggunakan: sudo systemctl status executor.service"
}

display_log() {
    echo "Menampilkan log dari service executor:"
    sudo journalctl -u executor.service -f
}

remove_old_service
update_system
download_and_extract_binary
set_environment_variables
set_private_key
set_enabled_networks
create_systemd_service
start_service
display_log
