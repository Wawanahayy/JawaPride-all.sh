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

# Menampilkan pilihan chain
echo "Pilih Chain yang diinginkan:"
echo "1. Ethereum Mainnet"
echo "2. Mantle"
echo "3. [Testnet] Holesky"
echo "4. [Testnet] Sepolia"

read -p "Masukkan pilihan Anda (1-4): " chain_choice

case $chain_choice in
    1)
        CHAIN="Ethereum Mainnet"
        ;;
    2)
        CHAIN="Mantle"
        ;;
    3)
        CHAIN="Holesky"
        ;;
    4)
        CHAIN="Sepolia"
        ;;
    *)
        print_colored "31;97" "Pilihan tidak valid. Silakan pilih antara 1 dan 4."
        exit 1
        ;;
esac

print_colored "32;97" "Anda memilih $CHAIN."

# Lanjutkan dengan proses selanjutnya
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

# ... (lanjutan dari kode Anda)
