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
    show "Loading NVM..."
    echo
    source "$NVM_DIR/nvm.sh"
else
    show "NVM not found, installing NVM..."
    echo
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    source "$NVM_DIR/nvm.sh"
fi

echo
show "Installing Node.js..."
echo
nvm install 22 && nvm alias default 22 && nvm use default
echo

show "Installing Foundry..."
echo
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
sleep 5
source ~/.bashrc
foundryup

show "Installing Bun..."
echo
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"
sleep 5
source ~/.bashrc
echo

show "Setting up Bun project..."
echo
mkdir -p ~/infinit && cd ~/infinit
bun init -y
bun add @infinit-xyz/cli
echo

show "Creating infinit.config.yaml..."
echo
cat <<EOF > infinit.config.yaml
network:
  name: holesky
  url: https://endpoints.omniatech.io/v1/eth/holesky/public
EOF
echo "File infinit.config.yaml berhasil dibuat."

show "Mengimpor wallet..."
echo
read -p "Masukkan private key wallet Anda: " PRIVATE_KEY

show "Inisialisasi Infinit CLI dan menghasilkan akun..."
echo
bunx infinit account import --private-key "$PRIVATE_KEY" || {
    echo "Gagal mengimpor akun. Periksa opsi dan dokumentasi."
    exit 1
}

read -p "Wallet address (masukkan address dari step sebelumnya) : " WALLET
echo
read -p "account ID (lakukan seperti diatas) : " ACCOUNT_ID
echo

show "Copy private key dan simpan "
echo
bunx infinit account export $ACCOUNT_ID

sleep 5
echo

# Removing old deployUniswapV3Action script if exists
mkdir -p src/scripts
rm -rf src/scripts/deployUniswapV3Action.script.ts

cat <<EOF > src/scripts/deployUniswapV3Action.script.ts
import { DeployUniswapV3Action, type actions } from '@infinit-xyz/uniswap-v3/actions'
import type { z } from 'zod'

type Param = z.infer<typeof actions['init']['paramsSchema']>

const params: Param = {
  "nativeCurrencyLabel": 'ETH',
  "proxyAdminOwner": '$WALLET',
  "factoryOwner": '$WALLET',
  "wrappedNativeToken": '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
}

const signer = {
  "deployer": "$ACCOUNT_ID"
}

export default { params, signer, Action: DeployUniswapV3Action }
EOF

show "Executing the UniswapV3 Action script..."
echo
bunx infinit script execute deployUniswapV3Action.script.ts
