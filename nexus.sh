#!/bin/bash

# Menampilkan logo JawaPride
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
sleep 5

# Deklarasi variabel untuk format teks
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
PINK='\033[1;35m'

# Fungsi untuk menampilkan pesan status
tampilkan() {
    case $2 in
        "error")
            echo -e "${PINK}${BOLD}❌ $1${NORMAL}"
            ;;
        "progress")
            echo -e "${PINK}${BOLD}⏳ $1${NORMAL}"
            ;;
        *)
            echo -e "${PINK}${BOLD}✅ $1${NORMAL}"
            ;;
    esac
}

# Nama layanan dan lokasi file systemd
NAMA_LAYANAN="nexus"
FILE_LAYANAN="/etc/systemd/system/$NAMA_LAYANAN.service"

# Menginstal Rust
tampilkan "Menginstal Rust..." "progress"
if ! source <(wget -O - https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/rust.sh); then
    tampilkan "Gagal menginstal Rust." "error"
    exit 1
fi

# Memperbarui daftar paket
tampilkan "Memperbarui daftar paket..." "progress"
if ! sudo apt update; then
    tampilkan "Gagal memperbarui daftar paket." "error"
    exit 1
fi

# Memeriksa apakah git sudah terinstal
if ! command -v git &> /dev/null; then
    tampilkan "Git belum terinstal. Menginstal git..." "progress"
    if ! sudo apt install git -y; then
        tampilkan "Gagal menginstal git." "error"
        exit 1
    fi
else
    tampilkan "Git sudah terinstal."
fi

# Menghapus repositori lama jika ada
if [ -d "$HOME/network-api" ]; then
    tampilkan "Menghapus repositori lama..." "progress"
    rm -rf "$HOME/network-api"
fi

sleep 3

# Mengkloning repositori Nexus-XYZ dari GitHub
tampilkan "Mengkloning repositori API jaringan Nexus-XYZ..." "progress"
if ! git clone https://github.com/nexus-xyz/network-api.git "$HOME/network-api"; then
    tampilkan "Gagal mengkloning repositori." "error"
    exit 1
fi

cd $HOME/network-api/clients/cli

# Menginstal dependensi yang diperlukan
tampilkan "Menginstal dependensi yang diperlukan..." "progress"
if ! sudo apt install pkg-config libssl-dev -y; then
    tampilkan "Gagal menginstal dependensi." "error"
    exit 1
fi

# Memeriksa status layanan nexus
if systemctl is-active --quiet nexus.service; then
    tampilkan "nexus.service sedang berjalan. Menghentikan dan menonaktifkannya..."
    sudo systemctl stop nexus.service
    sudo systemctl disable nexus.service
else
    tampilkan "nexus.service tidak berjalan."
fi

# Membuat layanan systemd baru
tampilkan "Membuat layanan systemd..." "progress"
if ! sudo bash -c "cat > $FILE_LAYANAN <<EOF
[Unit]
Description=Layanan Nexus XYZ Prover
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/network-api/clients/cli
Environment=NONINTERACTIVE=1
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.cargo/bin
ExecStart=$HOME/.cargo/bin/cargo run --release --bin prover -- beta.orchestrator.nexus.xyz
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"; then
    tampilkan "Gagal membuat file layanan systemd." "error"
    exit 1
fi

# Memuat ulang systemd dan memulai layanan
tampilkan "Memuat ulang systemd dan memulai layanan..." "progress"
if ! sudo systemctl daemon-reload; then
    tampilkan "Gagal memuat ulang systemd." "error"
    exit 1
fi

if ! sudo systemctl start $NAMA_LAYANAN.service; then
    tampilkan "Gagal memulai layanan." "error"
    exit 1
fi

if ! sudo systemctl enable $NAMA_LAYANAN.service; then
    tampilkan "Gagal mengaktifkan layanan." "error"
    exit 1
fi

# Menampilkan status layanan
tampilkan "Status layanan:" "progress"
if ! sudo systemctl status $NAMA_LAYANAN.service; then
    tampilkan "Gagal menampilkan status layanan." "error"
fi

# Selesai
tampilkan "Instalasi Nexus Prover dan pengaturan layanan selesai!"
