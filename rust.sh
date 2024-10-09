#!/bin/bash

# Tentukan lokasi di mana Rust akan diinstal
RUSTUP_HOME="$HOME/.rustup"
CARGO_HOME="$HOME/.cargo"

# Muat variabel lingkungan Rust
load_rust() {
    export RUSTUP_HOME="$HOME/.rustup"
    export CARGO_HOME="$HOME/.cargo"
    export PATH="$CARGO_HOME/bin:$PATH"
    if [ -f "$CARGO_HOME/env" ]; then
        source "$CARGO_HOME/env"
    fi
}

# Fungsi untuk menginstal dependensi sistem yang diperlukan untuk Rust
install_dependencies() {
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y build-essential libssl-dev curl
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall 'Development Tools' && sudo yum install -y openssl-devel curl
    elif command -v dnf &> /dev/null; then
        sudo dnf groupinstall 'Development Tools' && sudo dnf install -y openssl-devel curl
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu base-devel openssl curl
    else
        echo "Manajer paket tidak didukung. Silakan instal dependensi secara manual."
        exit 1
    fi
}

install_dependencies

# Periksa apakah Rust sudah diinstal
if command -v rustup &> /dev/null; then
    read -p "Ingin menginstal ulang atau memperbarui Rust? (y/n): " choice
    if [[ "$choice" == "y" ]]; then
        rustup self uninstall -y
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

load_rust 

# Perbaiki izin direktori Rust
if [ -d "$RUSTUP_HOME" ]; then
    sudo chmod -R 755 "$RUSTUP_HOME"
fi

if [ -d "$CARGO_HOME" ]; then
    sudo chmod -R 755 "$CARGO_HOME"
fi

# Fungsi untuk mencoba ulang sourcing lingkungan jika Cargo tidak ditemukan
retry_cargo() {
    local max_retries=3
    local retry_count=0
    local cargo_found=false

    while [ $retry_count -lt $max_retries ]; do
        if command -v cargo &> /dev/null; then
            cargo_found=true
            break
        else
            source "$CARGO_HOME/env"
            retry_count=$((retry_count + 1))
        fi
    done

    if [ "$cargo_found" = false ]; then
        echo "Cargo tidak dikenali setelah $max_retries percobaan."
        echo "Silakan muat ulang lingkungan secara manual dengan menjalankan: source \$HOME/.cargo/env"
        return 1
    fi

    return 0
}

rust_version=$(rustc --version)
cargo_version=$(cargo --version)

echo "Versi Rust: $rust_version"
echo "Versi Cargo: $cargo_version"

if [[ $SHELL == *"zsh"* ]]; then
    PROFILE="$HOME/.zshrc"
else
    PROFILE="$HOME/.bashrc"
fi

if ! grep -q "CARGO_HOME" "$PROFILE"; then
    {
        echo 'export RUSTUP_HOME="$HOME/.rustup"'
        echo 'export CARGO_HOME="$HOME/.cargo"'
        echo 'export PATH="$CARGO_HOME/bin:$PATH"'
        echo 'source "$CARGO_HOME/env"'
    } >> "$PROFILE"
fi

source "$PROFILE"

source "$CARGO_HOME/env"

retry_cargo
if [ $? -ne 0 ]; then
    exit 1
fi

echo "Instalasi dan pengaturan Rust telah selesai!"
