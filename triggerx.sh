#!/bin/bash

curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

echo -e "\n=== Step 1: Install Docker & Docker Compose ==="
apt-get update
apt-get install -y docker.io docker-compose
systemctl enable docker
systemctl start docker
docker --version
docker-compose --version

curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
echo -e "\n=== Step 2: Clone TriggerX Keeper Repo ==="
git clone https://github.com/trigg3rX/triggerx-keeper-setup.git
cd triggerx-keeper-setup

echo -e "\n=== Step 3: Setup .env file ==="
cp .env.example .env

# Prompt user input (Operator dulu, baru Private Key dengan bintang)
read -p "Masukkan OPERATOR_ADDRESS Anda: " OPERATOR_ADDRESS
echo -n "Masukkan PRIVATE_KEY Anda: "
read -s PRIVATE_KEY
echo
PUBLIC_IPV4=$(curl -s -4 ifconfig.me)
echo "Alamat IPv4 Publik Anda: $PUBLIC_IPV4"

# Predefined RPC
L1_RPC="https://endpoints.omniatech.io/v1/eth/holesky/public"
L2_RPC="https://base-sepolia.drpc.org"

# Isi file .env
sed -i "s|^PRIVATE_KEY=.*|PRIVATE_KEY=$PRIVATE_KEY|" .env
sed -i "s|^OPERATOR_ADDRESS=.*|OPERATOR_ADDRESS=$OPERATOR_ADDRESS|" .env
sed -i "s|^L1_RPC=.*|L1_RPC=$L1_RPC|" .env
sed -i "s|^L2_RPC=.*|L2_RPC=$L2_RPC|" .env
sed -i "s|^PUBLIC_IPV4_ADDRESS=.*|PUBLIC_IPV4_ADDRESS=$PUBLIC_IPV4|" .env

echo -e "\n=== Step 4: Generate PEER_ID (Lewati jika othentic-cli tidak ada) ==="
if command -v othentic-cli &> /dev/null; then
  PEER_ID=$(othentic-cli node get-id --node-type attester | sed 's/^Your node Peer ID is: //' | tr -d '\n')
  sed -i "s/^PEER_ID=.*/PEER_ID=$PEER_ID/" .env
  echo "PEER_ID berhasil dibuat: $PEER_ID"
else
  echo "othentic-cli tidak ditemukan. Anda perlu menambahkan PEER_ID secara manual ke file .env"
fi

echo -e "\n=== Step 5: Register Eigen Layer ==="
if [ -n "$PRIVATE_KEY" ]; then
  othentic-cli operator register-eigenlayer --private-key "$PRIVATE_KEY"
else
  echo "PRIVATE_KEY tidak ditemukan, silakan pastikan PRIVATE_KEY telah diinput dengan benar."
fi

echo -e "\n✅ Setup selesai!"
echo -e "➡ Jalankan Keeper Anda dengan:\n"
echo -e "cd triggerx-keeper-setup"

./triggerx.sh start
./triggerx.sh status
./triggerx.sh logs
