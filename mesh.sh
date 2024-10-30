#!/bin/bash

# Fungsi untuk mencetak pesan dengan warna yang berganti-ganti
print_colored() {
  local text="$1"
  local colors=(31 32 33 34 35 36 37) # Warna ANSI
  local color_index=0

  for ((i=0; i<${#text}; i++)); do
    # Mengambil warna dari array
    local color=${colors[$color_index]}
    # Mencetak karakter dengan warna
    printf "\e[${color}m${text:i:1}\e[0m"
    
    # Mengganti warna untuk karakter berikutnya
    color_index=$(( (color_index + 1) % ${#colors[@]} ))
    sleep 0.1 # Delay untuk efek
  done
  echo # Mencetak newline
}

echo "Menampilkan logo JWPA"
wget -O loader.sh https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/loader.sh && chmod +x loader.sh && ./loader.sh

# Menampilkan logo dengan warna berganti-ganti
print_colored "Memperbarui daftar paket..."
apt update
apt upgrade -y

rm -rf blockmesh-cli.tar.gz target

if ! command -v docker &> /dev/null; then
    print_colored "Docker belum terinstal. Menginstal Docker..."
    apt-get install -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
else
    print_colored "Docker sudah terinstal, melewati..."
fi

print_colored "Menginstal Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

print_colored "Mengunduh CLI BlockMesh..."
curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.316/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
tar -xzf blockmesh-cli.tar.gz

read -p "Masukkan email BlockMesh Anda: " email
read -s -p "Masukkan password BlockMesh Anda: " password
echo

print_colored "Membuat kontainer Docker untuk CLI BlockMesh..."
docker run -it --rm \
    --name blockmesh-cli-container \
    -v $(pwd)/target/release:/app \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"

# Menyimpan timestamp dengan timezone GMT+7
timestamp=$(date +"%Y-%m-%d %H:%M:%S GMT+7")
print_colored "[$timestamp] Session Email: $email: Successfully submitted uptime report"
