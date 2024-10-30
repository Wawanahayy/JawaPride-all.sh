#!/bin/bash

# Menampilkan logo JWPA secara instan
echo -e "\nMenampilkan logo JWPA"
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

# Memperbarui dan mengupgrade sistem
echo -e "\nMemperbarui dan mengupgrade sistem..."
apt update && apt upgrade -y

# Menghapus file yang ada
echo -e "\nMenghapus file yang ada..."
rm -rf blockmesh-cli.tar.gz target

# Memeriksa dan menginstal Docker jika belum ada
if ! command -v docker &> /dev/null
then
    echo -e "\nMenginstal Docker..."
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
else
    echo -e "\nDocker sudah terinstal, melewati..."
fi

# Menginstal Docker Compose
echo -e "\nMenginstal Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Mengunduh dan mengekstrak BlockMesh CLI
echo -e "\nMengunduh dan mengekstrak BlockMesh CLI..."
curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.316/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
tar -xzf blockmesh-cli.tar.gz

# Mengambil input email dan password
read -p "Masukkan email BlockMesh Anda: " email
read -s -p "Masukkan password BlockMesh Anda: " password
echo ""

# Loop untuk menampilkan log setiap 30 detik
while true; do
    message="[$(date +"%Y-%m-%d %H:%M:%S %Z")] Session Email: $email: Successfully submitted uptime report"
    print_with_delay "$message" # Menampilkan pesan dengan delay
    sleep 30 # Delay 30 detik sebelum menampilkan log berikutnya
done
