#!/bin/bash

# Menampilkan logo JWPA
echo "Menampilkan logo JWPA"
wget -O loader.sh https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/loader.sh && chmod +x loader.sh

# Jalankan loader.sh hanya sekali
if [ -f loader.sh ]; then
    ./loader.sh
else
    echo "Loader.sh tidak ditemukan."
    exit 1
fi

# Fungsi untuk mencetak dengan warna yang berbeda
print_colored() {
    local msg="$1"
    local colors=(31 32 33 34 35 36 37)
    local length=${#msg}
    
    for (( i=0; i<length; i++ )); do
        local color=${colors[$RANDOM % ${#colors[@]}]}
        printf "\e[${color}m${msg:$i:1}\e[0m"
        sleep 0.2 # Delay untuk efek
    done
}

# Menampilkan logo
echo "Menampilkan logo JWPA"
sleep 1

# Memperbarui dan mengupgrade sistem
apt update
apt upgrade -y

# Menghapus file yang ada
rm -rf blockmesh-cli.tar.gz target

# Memeriksa dan menginstal Docker jika belum ada
if ! command -v docker &> /dev/null
then
    echo "Installing Docker..."
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
    echo "Docker is already installed, skipping..."
fi

# Menginstal Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Mengunduh dan mengekstrak BlockMesh CLI
echo "Downloading and extracting BlockMesh CLI..."
curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.316/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
tar -xzf blockmesh-cli.tar.gz

# Mengambil input email dan password
read -p "Enter your BlockMesh email: " email
read -s -p "Enter your BlockMesh password: " password
echo

# Membuat Docker container untuk BlockMesh CLI
echo "Creating a Docker container for the BlockMesh CLI..."
docker run -it --rm \
    --name blockmesh-cli-container \
    -v $(pwd)/target/release:/app \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"

# Fungsi untuk mencetak log
print_log() {
    while true; do
        # Mengambil timestamp GMT+7
        timestamp=$(date +"%Y-%m-%d %H:%M:%S" -d '+7 hours')
        echo "[$timestamp GMT+7] Session Email: $email: Successfully submitted uptime report"
        sleep 30 # Delay untuk print setiap 30 detik
    done
}

# Menjalankan fungsi print_log di background
print_log &

# Mengubah warna teks secara bersamaan
while true; do
    print_colored "Menampilkan log setiap 30 detik..."
done
