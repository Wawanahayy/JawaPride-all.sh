#!/bin/bash

print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

display_colored_text() {
    print_colored "46;30" "========================================================="
    print_colored "45;97" "======================  INFINIT ========================="
    print_colored "43;30" "============== create all by JAWA-PRIDE  ================"
    print_colored "41;97" "=========== https://t.me/AirdropJP_JawaPride ============"
    print_colored "44;30" "========================================================="
}

loading_step() {
    display_colored_text
    print_colored "35;97" "$1"
    echo
}

loading_step "Loading NVM..."
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
else
    loading_step "NVM not found, installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    source "$NVM_DIR/nvm.sh"
fi

loading_step "Installing Node.js..."
nvm install 22 && nvm alias default 22 && nvm use default
print_colored "35;97" "Node.js installed successfully."
echo

loading_step "Installing Foundry..."
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
source ~/.bashrc
foundryup
print_colored "35;97" "Foundry installed successfully."
echo

loading_step "Installing Bun..."
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"
source ~/.bashrc
print_colored "35;97" "Bun installed successfully."
echo

loading_step "Setting up Bun project..."
mkdir JawaPride && cd JawaPride
bun init -y
bun add @infinit-xyz/cli
print_colored "35;97" "Bun project set up successfully."
echo

loading_step "Initializing Infinit CLI and generating account..."
bunx infinit init
bunx infinit account generate
echo

read -p "What is your wallet address (Input the address from the step above) : " WALLET
echo
read -p "What is your account ID (entered in the step above) : " ACCOUNT_ID
echo

print_colored "35;97" "Copy this private key and save it somewhere, this is the private key of this wallet"
echo
bunx infinit account export $ACCOUNT_ID

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

# Menambahkan pilihan input
echo "Pilih metode yang diinginkan:"
echo "1. Metode 1"
echo "2. Metode 2"
echo "3. Metode 3"
echo "4. Metode 4"

read -p "Masukkan pilihan Anda (1-4): " pilihan

case $pilihan in
    1)
        print_colored "32;97" "Anda memilih Metode 1."
        ;;
    2)
        print_colored "32;97" "Anda memilih Metode 2."
        ;;
    3)
        print_colored "32;97" "Anda memilih Metode 3."
        ;;
    4)
        print_colored "32;97" "Anda memilih Metode 4."
        ;;
    *)
        print_colored "31;97" "Pilihan tidak valid. Silakan pilih antara 1 dan 4."
        exit 1
        ;;
esac

loading_step "Executing the UniswapV3 Action script..."
bunx infinit script execute deployUniswapV3Action.script.ts
