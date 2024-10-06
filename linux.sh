#!/bin/bash

# Jalur penyimpanan skrip
SCRIPT_PATH="$HOME/Linux.sh"

# Tampilkan Logo
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
sleep 5

# Periksa apakah Docker sudah terinstal
if ! command -v docker &> /dev/null; then
    echo "Docker belum terinstal, sedang menginstal..."
    
    # Tampilkan loading
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
    
    # Perbarui sistem
    sudo apt update -y && sudo apt upgrade -y

    # Tampilkan loading
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

    # Hapus versi lama
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg
    done

    # Tampilkan loading
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

    # Instal paket yang diperlukan
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Tampilkan loading
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

    # Tambahkan sumber Docker
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Tampilkan loading
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

    # Perbarui lagi dan instal Docker
    sudo apt update -y && sudo apt upgrade -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Tampilkan loading
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

    # Periksa versi Docker
    docker --version
else
    echo "Docker sudah terinstal, versi: $(docker --version)"
fi

# Dapatkan jalur relatif
relative_path=$(realpath --relative-to=/usr/share/zoneinfo /etc/localtime)
echo "Jalur relatif adalah: $relative_path"

# Tampilkan loading
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

# Buat direktori chromium dan masuk
mkdir -p $HOME/chromium
cd $HOME/chromium
echo "Sudah masuk ke direktori chromium"

# Tampilkan loading
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

# Dapatkan input pengguna
read -p "Masukkan CUSTOM_USER: " CUSTOM_USER
read -sp "Masukkan PASSWORD: " PASSWORD
echo

# Tampilkan loading
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

# Buat file docker-compose.yaml
cat <<EOF > docker-compose.yaml
---
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined #opsional
    environment:
      - CUSTOM_USER=$CUSTOM_USER
      - PASSWORD=$PASSWORD
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - CHROME_CLI=https://x.com/ferdie_jhovie #opsional
    volumes:
      - /root/chromium/config:/config
    ports:
      - 3010:3000   #Ubah 3010 ke port favorit Anda jika perlu
      - 3011:3001   #Ubah 3011 ke port favorit Anda jika perlu
    shm_size: "1gb"
    restart: unless-stopped
EOF

echo "File docker-compose.yaml sudah dibuat, konten sudah diimpor."

# Tampilkan loading
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

# Jalankan Docker Compose
docker compose up -d
echo "Docker Compose sudah dimulai."

# Tampilkan loading
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

echo "Penerapan selesai, silakan buka browser untuk beroperasi."
