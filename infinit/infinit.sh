#!/bin/bash

print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

show() {
    print_colored "36;30" "$1"  # Teks berwarna cyan untuk fungsi show
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

# Pengaturan NVM dan instalasi Node.js
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
if ! nvm install 22; then
    echo "Instalasi Node.js gagal."
    exit 1
fi
nvm alias default 22 && nvm use default
echo

show "Menginstal Foundry..."
if ! curl -L https://foundry.paradigm.xyz | bash; then
    echo "Instalasi Foundry gagal."
    exit 1
fi
export PATH="$HOME/.foundry/bin:$PATH"
sleep 5
source ~/.bashrc
foundryup

show "Menginstal Bun..."
if ! curl -fsSL https://bun.sh/install | bash; then
    echo "Instalasi Bun gagal."
    exit 1
fi
export PATH="$HOME/.bun/bin:$PATH"
sleep 5
source ~/.bashrc
echo

show "Menyiapkan proyek Bun..."
if [ ! -d "JawaPride" ]; then
    mkdir JawaPride && cd JawaPride
else
    cd JawaPride
fi
bun init -y
bun add @infinit-xyz/cli
echo

show "Menginisialisasi Infinit CLI dan menghasilkan akun..."
bunx infinit init
bunx infinit account generate
echo

read -p "Apa alamat dompet Anda (Masukkan alamat dari langkah di atas): " WALLET
echo
read -p "Apa ID akun Anda (dimasukkan di langkah di atas): " ACCOUNT_ID
echo

show "Salin kunci pribadi ini dan simpan di tempat yang aman, ini adalah kunci pribadi dari dompet ini"
echo
bunx infinit account export $ACCOUNT_ID

sleep 5
echo

# Menghapus skrip deployUniswapV3Action yang lama jika ada
rm -rf src/scripts/deployUniswapV3Action.script.ts

cat <<EOF > src/scripts/deployUniswapV3Action.script.ts
import { DeployUniswapV3Action, type actions } from '@infinit-xyz/uniswap-v3/actions'
import type { z } from 'zod'

type Param = z.infer<typeof actions['init']['paramsSchema']>

// Parameter yang akan digunakan
const params: Param = {
  "nativeCurrencyLabel": 'ETH',
  "proxyAdminOwner": "$WALLET",
  "factoryOwner": "$WALLET",
  "wrappedNativeToken": '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
}

// Konfigurasi signer
const signer = {
  "deployer": "$ACCOUNT_ID"
}

export default { params, signer, Action: DeployUniswapV3Action }
EOF

show "Menjalankan skrip UniswapV3 Action..."
bunx infinit script execute deployUniswapV3Action.script.ts

