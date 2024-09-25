#!/bin/bash

print_colored() {
    local color=$1
    shift
    echo -e "\e[${color}m$@\e[0m"
}

display_colored_text() {
    print_colored "42;30" "========================================================="
    print_colored "46;30" "========================================================="
    print_colored "45;97" "======================   T3EN   ========================="
    print_colored "43;30" "============== create all by JAWA-PRIDE  ================"
    print_colored "41;97" "=========== https://t.me/AirdropJP_JawaPride ============"
    print_colored "44;30" "========================================================="
    print_colored "42;97" "========================================================="
}

display_colored_text
sleep 5

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "Loading NVM..."
    source "$NVM_DIR/nvm.sh"
else
    echo "NVM not found, installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    source "$NVM_DIR/nvm.sh"
fi

echo
echo "Installing Node.js..."
nvm install 22 && nvm alias default 22 && nvm use default
echo

echo "Installing Foundry..."
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
sleep 5
source ~/.bashrc
foundryup

echo "Installing Bun..."
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"
sleep 5
source ~/.bashrc
echo

echo "Setting up Bun project..."
mkdir -p ~/infinit && cd ~/infinit
bun init -y
bun add @infinit-xyz/cli
echo

echo "Creating infinit.config.yaml..."
cat <<EOF > infinit.config.yaml
network:
  name: holesky
  url: https://endpoints.omniatech.io/v1/eth/holesky/public
EOF
echo "File infinit.config.yaml berhasil dibuat."

echo "Mengimpor wallet..."
read -p "Masukkan private key wallet Anda: " PRIVATE_KEY

echo "Inisialisasi Infinit CLI dan menghasilkan akun..."
bunx infinit account import --private-key "$PRIVATE_KEY"

read -p "Wallet address (masukkan address dari step sebelumnya): " WALLET
echo
read -p "Account ID (lakukan seperti diatas): " ACCOUNT_ID
echo

echo "Copy private key dan simpan"
bunx infinit account export "$ACCOUNT_ID"

sleep 5
echo
# Removing old deployUniswapV3Action script if exists
rm -rf src/scripts/deployUniswapV3Action.script.ts

cat <<EOF > src/scripts/deployUniswapV3Action.script.ts
import { DeployUniswapV3Action, type actions } from '@infinit-xyz/uniswap-v3/actions'
import type { z } from 'zod'

type Param = z.infer<typeof actions['init']['paramsSchema']>

// TODO: Replace with actual params
const params: Param = {
  // Native currency label (e.g., ETH)
  "nativeCurrencyLabel": 'ETH',

  // Address of the owner of the proxy admin
  "proxyAdminOwner": '$WALLET',

  // Address of the owner of factory
  "factoryOwner": '$WALLET',

  // Address of the wrapped native token (e.g., WETH)
  "wrappedNativeToken": '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
}

// Signer configuration
const signer = {
  "deployer": "$ACCOUNT_ID"
}

export default { params, signer, Action: DeployUniswapV3Action }
EOF

echo "Skrip UniswapV3 Action sudah disiapkan. Anda dapat menjalankan skrip ini secara manual."
