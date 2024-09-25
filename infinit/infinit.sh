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

display_colored_text
sleep 5 

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    print_colored "35;97" "Loading NVM..."
    echo
    source "$NVM_DIR/nvm.sh"
else
    print_colored "35;97" "NVM not found, installing NVM..."
    echo
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    source "$NVM_DIR/nvm.sh"
fi

echo
print_colored "35;97" "Installing Node.js..."
echo
nvm install 22 && nvm alias default 22 && nvm use default
echo

print_colored "35;97" "Installing Foundry..."
echo
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
sleep 5
source ~/.bashrc
foundryup

print_colored "35;97" "Installing Bun..."
echo
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"
sleep 5
source ~/.bashrc
echo

print_colored "35;97" "Setting up Bun project..."
echo
mkdir JawaPride && cd JawaPride
bun init -y
bun add @infinit-xyz/cli
echo

print_colored "35;97" "Initializing Infinit CLI and generating account..."
echo
bunx infinit init
bunx infinit account generate
echo

read -p "What is your wallet address (Input the address from the step above) : " WALLET
echo
read -p "What is your account ID / BUAT ID (entered in the step above) : " ACCOUNT_ID
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

print_colored "35;97" "Executing the UniswapV3 Action script..."
echo
bunx infinit script execute deployUniswapV3Action.script.ts
