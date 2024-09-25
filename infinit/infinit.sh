#!/bin/bash


print_colored() {
    echo -e "\e[$1m$2\e[0m"
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

curl -s https://raw.githubusercontent.com/anggasec28/logo/refs/heads/main/logo.sh | bash
sleep 3

function show {
  echo -e "\e[1;34m$1\e[0m"
}

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    show "Memuat NVM..."
    echo
    source "$NVM_DIR/nvm.sh"
else
    show "NVM tidak ditemukan, menginstal NVM..."
    echo
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    source "$NVM_DIR/nvm.sh"
fi

echo
show "Menginstal Node.js..."
echo
nvm install 22 && nvm alias default 22 && nvm use default
echo

show "Menginstal Foundry..."
echo
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
sleep 5
source ~/.bashrc
foundryup

show "Menginstal Bun..."
echo
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"
sleep 5
source ~/.bashrc
echo

show "Menyiapkan proyek Bun..."
echo
mkdir infinit && cd infinit
bun init -y
bun add @infinit-xyz/cli
echo

show "Inisialisasi Infinit CLI dan menghasilkan akun..."
echo
bunx infinit init
bunx infinit account generate
echo

read -p "Alamat dompet (masukkan address dari step sebelumnya) : " WALLET
echo
read -p "ID akun (lakukan seperti diatas) : " ACCOUNT_ID
echo

show "Salin kunci pribadi dan simpan"
echo
bunx infinit account export $ACCOUNT_ID

sleep 5
echo

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

show "Menjalankan skrip UniswapV3..."
echo
bunx infinit script execute deployUniswapV3Action.script.ts
