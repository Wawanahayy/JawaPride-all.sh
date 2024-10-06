#!/bin/bash

# Jalur penyimpanan skrip
SCRIPT_PATH="$HOME/Linux.sh"
LOG_FILE="$HOME/installation.log"  # File log untuk mencatat aktivitas

# Tampilkan Logo dan catat log
echo "Menampilkan logo..." | tee -a $LOG_FILE
curl -s https://raw.githubusercontent.com/sdohuajia/Hyperlane/refs/heads/main/logo.sh | bash >> $LOG_FILE 2>&1
sleep 3

# Tampilkan loading dan catat log
echo "Menampilkan loading..." | tee -a $LOG_FILE
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash >> $LOG_FILE 2>&1

# Periksa apakah Docker sudah terinstal
if ! command -v docker &> /dev/null; then
    echo "Docker belum terinstal, sedang menginstal..." | tee -a $LOG_FILE
    
    # Tampilkan loading dan catat log
    echo "Menampilkan loading..." | tee -a $LOG_FILE
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash >> $LOG_FILE 2>&1
    
    # Perbarui sistem dan catat log
    echo "Memperbarui sistem..." | tee -a $LOG_FILE
    sudo apt update -y >> $LOG_FILE 2>&1 && sudo apt upgrade -y >> $LOG_FILE 2>&1

    # Hapus versi lama dan catat log
    echo "Menghapus versi lama Docker..." | tee -a $LOG_FILE
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg >> $LOG_FILE 2>&1
    done

    # Instal paket yang diperlukan dan catat log
    echo "Menginstal paket yang diperlukan..." | tee -a $LOG_FILE
    sudo apt-get update >> $LOG_FILE 2>&1
    sudo apt-get install -y ca-certificates curl gnupg >> $LOG_FILE 2>&1
    sudo install -m 0755 -d /etc/apt/keyrings >> $LOG_FILE 2>&1
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg >> $LOG_FILE 2>&1
    sudo chmod a+r /etc/apt/keyrings/docker.gpg >> $LOG_FILE 2>&1

    # Tambahkan sumber Docker dan catat log
    echo "Menambahkan sumber Docker..." | tee -a $LOG_FILE
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Perbarui lagi dan instal Docker
    echo "Memperbarui dan menginstal Docker..." | tee -a $LOG_FILE
    sudo apt update -y >> $LOG_FILE 2>&1 && sudo apt upgrade -y >> $LOG_FILE 2>&1
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >> $LOG_FILE 2>&1

    # Periksa versi Docker dan catat log
    echo "Memeriksa versi Docker..." | tee -a $LOG_FILE
    docker --version >> $LOG_FILE 2>&1
else
    echo "Docker sudah terinstal, versi: $(docker --version)" | tee -a $LOG_FILE
fi

# Dapatkan jalur relatif dan catat log
relative_path=$(realpath --relative-to=/usr/share/zoneinfo /etc/localtime)
echo "Jalur relatif adalah: $relative_path" | tee -a $LOG_FILE

# Buat direktori chromium dan masuk
mkdir -p $HOME/chromium
cd $HOME/chromium
echo "Sudah masuk ke direktori chromium" | tee -a $LOG_FILE

# Tampilkan loading dan catat log
echo "Menampilkan loading..." | tee -a $LOG_FILE
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash >> $LOG_FILE 2>&1

# Dapatkan input pengguna dan catat log
read -p "Masukkan CUSTOM_USER: " CUSTOM_USER
read -sp "Masukkan PASSWORD: " PASSWORD
echo | tee -a $LOG_FILE

# Buat file docker-compose.yaml dan catat log
echo "Membuat file docker-compose.yaml..." | tee -a $LOG_FILE
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

echo "File docker-compose.yaml sudah dibuat, konten sudah diimpor." | tee -a $LOG_FILE

# Tampilkan loading dan catat log
echo "Menampilkan loading..." | tee -a $LOG_FILE
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash >> $LOG_FILE 2>&1

# Jalankan Docker Compose dan catat log
echo "Menjalankan Docker Compose..." | tee -a $LOG_FILE
docker compose up -d >> $LOG_FILE 2>&1
echo "Docker Compose sudah dimulai." | tee -a $LOG_FILE

# Tampilkan loading dan catat log
echo "Menampilkan loading..." | tee -a $LOG_FILE
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash >> $LOG_FILE 2>&1

echo "Penerapan selesai, silakan buka browser untuk beroperasi." | tee -a $LOG_FILE
