#!/bin/bash

curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
sleep 5

set -e
trap 'echo "Terjadi kesalahan, script dihentikan."' ERR

install_dependencies() {
    for cmd in git make jq; do
        if ! command -v $cmd &> /dev/null; then
            echo "$cmd belum terinstal. Menginstal $cmd..."
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo apt update
                sudo apt install -y $cmd
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                brew install $cmd
            else
                echo "OS tidak didukung. Silakan instal $cmd secara manual."
                exit 1
            fi
        fi
    done
    echo "Semua dependensi telah diinstal."
}

check_go_version() {
    if command -v go >/dev/null 2>&1; then
        CURRENT_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        MINIMUM_GO_VERSION="1.22.2"
        if [ "$(printf '%s\n' "$MINIMUM_GO_VERSION" "$CURRENT_GO_VERSION" | sort -V | head -n1)" = "$MINIMUM_GO_VERSION" ]; then
            echo "Versi Go saat ini memenuhi syarat: $CURRENT_GO_VERSION"
        else
            echo "Versi Go saat ini ($CURRENT_GO_VERSION) lebih rendah dari yang disyaratkan ($MINIMUM_GO_VERSION), akan menginstal Go versi terbaru."
            install_go
        fi
    else
        echo "Go tidak terdeteksi, menginstal Go."
        install_go
    fi
}

install_go() {
    wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
    echo "Go telah terinstal, versi: $(go version)"
}

install_node() {
    echo "npm tidak ditemukan. Menginstal Node.js dan npm..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install node
    else
        echo "OS tidak didukung. Silakan instal Node.js dan npm secara manual."
        exit 1
    fi
    echo "Node.js dan npm telah diinstal."
}

install_pm2() {
    if ! command -v npm &> /dev/null; then
        echo "npm tidak terinstal."
        install_node
    fi
    if ! command -v pm2 &> /dev/null; then
        echo "pm2 tidak ditemukan. Menginstal pm2..."
        npm install -g pm2
    else
        echo "pm2 sudah terinstal."
    fi
}

download_and_setup() {
    LATEST_VERSION=$(curl -s https://api.github.com/repos/hemilabs/heminetwork/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
    DOWNLOAD_URL="https://github.com/hemilabs/heminetwork/releases/download/${LATEST_VERSION}/heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz"
    wget "$DOWNLOAD_URL" -O heminetwork_linux_amd64.tar.gz
    TARGET_DIR="$HOME/heminetwork"
    mkdir -p "$TARGET_DIR"
    tar -xvf heminetwork_linux_amd64.tar.gz -C "$TARGET_DIR"
    mv "$TARGET_DIR/heminetwork_"* "$TARGET_DIR/"
    rmdir "$TARGET_DIR/heminetwork_"*
    cd "$TARGET_DIR"
    ./popmd --help
    ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json
}

setup_environment() {
    cd "$HOME/heminetwork"
    cat ~/popm-address.json
    POPM_BTC_PRIVKEY=$(jq -r '.private_key' ~/popm-address.json)
    read -p "Cek nilai sats/vB di https://mempool.space/zh/testnet dan masukkan: " POPM_STATIC_FEE
    export POPM_BTC_PRIVKEY=$POPM_BTC_PRIVKEY
    export POPM_STATIC_FEE=$POPM_STATIC_FEE
    export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public
}

start_popmd() {
    cd "$HOME/heminetwork"
    pm2 start ./popmd --name popmd
    pm2 save
    echo "popmd telah dijalankan melalui pm2."
}

backup_address() {
    echo "Simpan berikut ini secara lokal:"
    cat ~/popm-address.json
}

view_logs() {
    cd "$HOME/heminetwork"
    pm2 logs popmd
}

update_to_latest() {
    echo "Memulai pembaruan ke versi terbaru"
    pm2 delete popmd || {
        echo "Gagal menghapus proses popmd di pm2 atau proses tidak ada."
    }
    rm -rf "$HOME/heminetwork"
    wget https://github.com/hemilabs/heminetwork/releases/latest/download/heminetwork_linux_amd64.tar.gz -O /tmp/heminetwork_latest.tar.gz
    mkdir -p "$HOME/heminetwork"
    tar -xzf /tmp/heminetwork_latest.tar.gz -C "$HOME/heminetwork" --strip-components=1
    setup_environment
    start_popmd
    echo "Pembaruan ke versi terbaru selesai dan popmd telah dijalankan ulang."
}

main_menu() {
    clear
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
    while true; do
        echo "Silakan pilih opsi:"
        echo "1. Unduh dan setup Heminetwork"
        echo "2. Masukkan private_key dan sats/vB"
        echo "3. Jalankan popmd"
        echo "4. Backup informasi alamat"
        echo "5. Lihat log"
        echo "6. Perbarui ke versi terbaru"
        echo "7. Keluar"
        read -p "Masukkan pilihan (1-7): " choice
        case $choice in
            1)
                download_and_setup
                ;;
            2)
                setup_environment
                ;;
            3)
                start_popmd
                ;;
            4)
                backup_address
                ;;
            5)
                view_logs
                ;;
            6)
                update_to_latest
                ;;
            7)
                echo "Keluar dari script."
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, coba lagi."
                ;;
        esac
    done
}

main_menu
