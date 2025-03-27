#!/bin/bash

# Fungsi untuk mencetak teks berwarna
printf_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

# Fungsi untuk menampilkan teks berwarna di bagian atas skrip
display_colored_text() {
    printf_colored "40;96" "============================================================"
    printf_colored "42;37" "=======================  J.W.P.A  =========================="
    printf_colored "45;97" "================= @AirdropJP_JawaPride ====================="
    printf_colored "43;30" "=============== https://x.com/JAWAPRIDE_ID ================="
    printf_colored "41;97" "============= https://linktr.ee/Jawa_Pride_ID =============="
    printf_colored "44;30" "============================================================"
}

# Fungsi menu utama
function menu_utama() {
    while true; do
        clear
        display_colored_text
        echo "================================================================"
        echo "Untuk keluar dari skrip, tekan tombol Ctrl + C."
        echo "Silakan pilih operasi yang ingin dijalankan:"
        echo "1) Deploy Kontrak"
        echo "2) Interaksi Kontrak"
        echo "3) Keluar"
        read -p "Masukkan pilihan Anda: " pilihan

        case $pilihan in
            1)
                deploy_kontrak
                ;;
            2)
                interaksi_kontrak
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, silakan coba lagi."
                sleep 2
                ;;
        esac
    done
}

# Fungsi untuk deploy kontrak
deploy_kontrak() {
    echo "Memulai deploy kontrak..."
    
    # Periksa apakah Rust sudah terinstal
    if command -v rustc &> /dev/null
    then
        echo "Rust sudah terinstal, versi saat ini: $(rustc --version)"
    else
        echo "Rust belum terinstal, menginstal sekarang..."
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        source "$HOME/.cargo/env"
        echo "Rust berhasil diinstal, versi saat ini: $(rustc --version)"
    fi

    # Periksa apakah jq sudah terinstal
    if command -v jq &> /dev/null
    then
        echo "jq sudah terinstal, versi saat ini: $(jq --version)"
    else
        echo "jq belum terinstal, menginstal sekarang..."
        sudo apt-get update && sudo apt-get install -y jq
        echo "jq berhasil diinstal, versi saat ini: $(jq --version)"
    fi

    # Unduh dan jalankan skrip instalasi Seismic Foundry
    echo "Menginstal Seismic Foundry..."
    curl -L -H "Accept: application/vnd.github.v3.raw" \
     "https://api.github.com/repos/SeismicSystems/seismic-foundry/contents/sfoundryup/install?ref=seismic" | bash

    # Perbarui PATH
    export PATH="$HOME/.seismic/bin:$PATH"

    # Jalankan sfoundryup
    echo "Menjalankan sfoundryup..."
    sfoundryup

    # Clone repository SeismicSystems/try-devnet jika belum ada
    if [ ! -d "try-devnet" ]; then
        git clone --recurse-submodules https://github.com/SeismicSystems/try-devnet.git
    fi
    cd try-devnet/packages/contract/
    bash script/deploy.sh

    echo "Deploy kontrak selesai, tekan tombol apa saja untuk kembali ke menu utama..."
    read -n 1 -s
}

# Fungsi untuk interaksi dengan kontrak
interaksi_kontrak() {
    echo "Memulai interaksi dengan kontrak..."
    
    # Instal Bun
    echo "Menginstal Bun..."
    curl -fsSL https://bun.sh/install | bash
    source ~/.bashrc
    
    # Instal dependensi
    cd /root/try-devnet/packages/cli/
    bun install
    bash script/transact.sh

    echo "Interaksi kontrak selesai, tekan tombol apa saja untuk kembali ke menu utama..."
    read -n 1 -s
}

# Jalankan menu utama
menu_utama
