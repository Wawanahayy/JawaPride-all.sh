#!/bin/bash

# Display setup
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

apt update && apt install -y bash

sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev  -y

bash -i <(curl -s https://install.aztec.network)

aztec-up 0.85.0-alpha-testnet.5

echo "====================================="
echo "     🚀 Aztec Sequencer One-Click    "
echo "====================================="

# Fungsi untuk mendeteksi IP publik
detect_ip() {
  echo "[*] Mendeteksi IP publik VPS Anda..."
  IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)
  if [[ -z "$IP" ]]; then
    echo "[!] Gagal mendeteksi IP. Masukkan secara manual."
    read -p "Masukkan IP Publik Anda: " IP
  else
    echo "[✔] IP publik terdeteksi: $IP"
  fi
}

# Cek dan muat file .env
if [ -f ".env" ]; then
  echo "[✔] Memuat konfigurasi dari .env..."
  source .env
else
  echo "[!] File .env tidak ditemukan. Meminta input manual..."

  read -p "Masukkan L1 RPC URL (contoh: https://rpc.sepolia.org): " ETHEREUM_HOSTS
  read -p "Masukkan L1 Consensus URL (contoh: https://consensus.sepolia.example.com): " L1_CONSENSUS_HOST_URLS
  read -p "Masukkan Ethereum Private Key: " VALIDATOR_PRIVATE_KEY
  read -p "Masukkan Ethereum Public Address (coinbase): " COINBASE

  detect_ip
  P2P_IP=$IP

  # Simpan ke file .env
  cat <<EOF > .env
ETHEREUM_HOSTS=$ETHEREUM_HOSTS
L1_CONSENSUS_HOST_URLS=$L1_CONSENSUS_HOST_URLS
VALIDATOR_PRIVATE_KEY=$VALIDATOR_PRIVATE_KEY
COINBASE=$COINBASE
P2P_IP=$P2P_IP
EOF
  echo "[✔] Konfigurasi disimpan ke .env"
fi

# Menambahkan /root/.aztec/bin ke PATH
echo "[*] Menambahkan /root/.aztec/bin ke PATH..."

echo "export PATH=\$PATH:/root/.aztec/bin" >> /root/.bash_profile

# Terapkan perubahan ke PATH
source /root/.bash_profile

# Allow akses di port 8080 dan 8545
echo "[*] Mengizinkan akses pada port 8080 dan 8545..."
# Firewall
ufw allow 22
ufw allow ssh
ufw enable

# Sequencer
ufw allow 40400
ufw allow 8080

echo "[🚀] Menjalankan node Aztec dalam sesi screen 'aztec-node'..."
screen -S aztec-node -dm bash -c "aztec start --node --archiver --sequencer \
  --network alpha-testnet \
  --l1-rpc-urls $ETHEREUM_HOSTS \
  --l1-consensus-host-urls $L1_CONSENSUS_HOST_URLS \
  --sequencer.validatorPrivateKey $VALIDATOR_PRIVATE_KEY \
  --sequencer.coinbase $COINBASE \
  --p2p.p2pIp $P2P_IP"
echo "[✔] Node sedang berjalan dalam screen bernama 'aztec-node'. Gunakan 'screen -r aztec-node' untuk melihat log."
