#!/bin/bash

# Berhenti jika terjadi kesalahan
set -e

# Tangkap kesalahan dan beri pesan
trap 'echo "Terjadi kesalahan, script dihentikan."' ERR

# Fungsi: Menginstal dependensi yang hilang (git dan make)
install_dependencies() {
    for cmd in git make; do
        if ! command -v $cmd &> /dev/null; then
            echo "$cmd belum terinstal. Menginstal $cmd..."

            # Deteksi tipe OS dan jalankan perintah instalasi yang sesuai
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

# Fungsi: Memeriksa apakah versi Go >= 1.22.2
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

# Fungsi: Memeriksa dan menginstal Node.js serta npm
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

# Fungsi: Instalasi pm2
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

# Fungsi 1: Mengunduh, mengekstrak, dan menjalankan perintah bantuan
download_and_setup() {
    wget https://github.com/hemilabs/heminetwork/releases/download/v0.4.3/heminetwork_v0.4.3_linux_amd64.tar.gz -O heminetwork_v0.4.3_linux_amd64.tar.gz

    # Buat folder target (jika belum ada)
    TARGET_DIR="$HOME/heminetwork"
    mkdir -p "$TARGET_DIR"

    # Ekstrak file ke folder target
    tar -xvf heminetwork_v0.4.3_linux_amd64.tar.gz -C "$TARGET_DIR"

    # Pindahkan file ke direktori heminetwork
    mv "$TARGET_DIR/heminetwork_v0.4.3_linux_amd64/"* "$TARGET_DIR/"
    rmdir "$TARGET_DIR/heminetwork_v0.4.3_linux_amd64"

    # Ganti direktori ke folder target
    cd "$TARGET_DIR"
    ./popmd --help
    ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json
}

# Fungsi 2: Menyiapkan variabel lingkungan
setup_environment() {
    cd "$HOME/heminetwork"
    cat ~/popm-address.json

    # Ambil private_key secara otomatis
    POPM_BTC_PRIVKEY=$(jq -r '.private_key' ~/popm-address.json)
    read -p "Cek nilai sats/vB di https://mempool.space/zh/testnet dan masukkan: " POPM_STATIC_FEE

    export POPM_BTC_PRIVKEY=$POPM_BTC_PRIVKEY
    export POPM_STATIC_FEE=$POPM_STATIC_FEE
    export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public
}

# Fungsi 3: Menjalankan popmd dengan pm2
start_popmd() {
    cd "$HOME/heminetwork"
    pm2 start ./popmd --name popmd
    pm2 save
    echo "popmd telah dijalankan melalui pm2."
}

# Fungsi 4: Backup popm-address.json
backup_address() {
    echo "Simpan berikut ini secara lokal:"
    cat ~/popm-address.json
}

# Fungsi 5: Melihat log
view_logs() {
    cd "$HOME/heminetwork"
    pm2 logs popmd
}

# Fungsi 6: Perbarui ke v0.4.3
update_to_v038() {
    echo "Memulai pembaruan ke v0.4.3"

    # Hentikan dan hapus proses popmd di pm2 (jika ada)
    echo "Mencoba menghentikan dan menghapus proses popmd di pm2..."
    pm2 delete popmd || {
        echo "Gagal menghapus proses popmd di pm2 atau proses tidak ada."
    }

    # Hapus folder lama heminetwork
    echo "Menghapus folder lama heminetwork..."
    rm -rf "$HOME/heminetwork"

    # Unduh dan ekstrak versi v0.4.3
    echo "Mengunduh arsip versi v0.4.3..."
    wget https://github.com/hemilabs/heminetwork/releases/download/v0.4.3/heminetwork_v0.4.3_linux_amd64.tar.gz -O /tmp/heminetwork_v0.4.3_linux_amd64.tar.gz

    echo "Mengekstrak arsip versi v0.4.3 ke folder heminetwork..."
    mkdir -p "$HOME/heminetwork"
    tar -xzf /tmp/heminetwork_v0.4.3_linux_amd64.tar.gz -C "$HOME/heminetwork" --strip-components=1

    # Menjalankan fungsi dari menu utama 2: Setup lingkungan
    echo "Menjalankan fungsi dari menu utama 2: Setup lingkungan"
    setup_environment

    # Jalankan popmd
    echo "Menjalankan popmd..."
    start_popmd

    echo "Pembaruan ke v0.4.3 selesai dan popmd telah dijalankan ulang."
}

# Menu utama
main_menu() {
    while true; do
        clear
        echo "=======================Dibuat oleh https://x.com/ccaannddyy11 dari komunitas https://t.me/niuwuriji======================="
        echo "Silakan pilih opsi:"
        echo "1. Unduh dan setup Heminetwork"
        echo "2. Masukkan private_key dan sats/vB"
        echo "3. Jalankan popmd"
        echo "4. Backup informasi alamat"
        echo "5. Lihat log"
        echo "6. Perbarui ke v0.4.3"
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
                update_to_v038
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

# Mulai menu utama
echo "Menyiapkan untuk meluncurkan menu utama..."
main_menu

