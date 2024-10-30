#!/bin/bash

# Fungsi untuk mencetak dengan warna yang berbeda
print_colored() {
  local msg="$1"
  local colors=(31 32 33 34 35 36 37)
  local length=${#msg}

  for (( i=0; i<length; i++ )); do
    local color=${colors[$RANDOM % ${#colors[@]}]}
    printf "\e[${color}m${msg:$i:1}\e[0m"
    sleep 0.2 # Delay untuk efek warna
  done
}

# Menampilkan logo JWPA
print_colored "Menampilkan logo JWPA"
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

# Mengambil timestamp GMT+7
timestamp() {
  date +"%Y-%m-%d %H:%M:%S" -d '+7 hours'
}

# Fungsi untuk mencetak log dengan warna yang berubah
log_with_color_change() {
  while true; do
    # Mencetak log dengan warna berubah
    print_colored "[$(timestamp) GMT+7] Session Email: $email: Successfully submitted uptime report"
    sleep 30 # Delay sebelum mencetak log berikutnya
  done
}

# Menjalankan log dalam background
log_with_color_change &

# Menjalankan BlockMesh CLI di Docker
docker run -it --rm \
    --name blockmesh-cli-container \
    -v $(pwd)/target/release:/app \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"
