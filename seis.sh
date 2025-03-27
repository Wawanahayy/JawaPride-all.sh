#!/bin/bash

# Fungsi menu utama
function menu_utama() {
    while true; do
        clear
        echo "Skrip ini ditulis oleh komunitas besar judi, hahaha. Twitter: @ferdie_jhovie."
        echo "Sumber terbuka dan gratis. Jangan percaya pada layanan berbayar!"
        echo "Jika ada masalah, hubungi Twitter. Ini satu-satunya akun resmi."
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
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y jq
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install jq
        else
            echo "Sistem tidak didukung, silakan instal jq secara manual."
            exit 1
        fi
        echo "jq berhasil diinstal, versi saat ini: $(jq --version)"
    fi

    # Periksa apakah unzip sudah terinstal
    if command -v unzip &> /dev/null
    then
        echo "unzip sudah terinstal."
    else
        echo "unzip belum terinstal, menginstal sekarang..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y unzip
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install unzip
        else
            echo "Sistem tidak didukung, silakan instal unzip secara manual."
            exit 1
        fi
        echo "unzip berhasil diinstal."
    fi

    # Unduh dan jalankan skrip instalasi Seismic Foundry
    echo "Menginstal Seismic Foundry..."
    curl -L \
     -H "Accept: application/vnd.github.v3.raw" \
     "https://api.github.com/repos/SeismicSystems/seismic-foundry/contents/sfoundryup/install?ref=seismic" | bash

    # Dapatkan PATH baru setelah instalasi
    NEW_PATH=$(bash -c 'source /root/.bashrc && echo $PATH')

    # Perbarui PATH untuk sesi saat ini
    export PATH="$NEW_PATH"

    # Pastikan ~/.seismic/bin ada dalam PATH
    if [[ ":$PATH:" != *":/root/.seismic/bin:"* ]]; then
        export PATH="/root/.seismic/bin:$PATH"
    fi

    # Cetak PATH saat ini untuk memastikan sfoundryup tersedia
    echo "PATH saat ini: $PATH"

    # Periksa apakah sfoundryup sudah terinstal
    if command -v sfoundryup &> /dev/null
    then
        echo "sfoundryup berhasil diinstal!"
    else
        echo "sfoundryup gagal diinstal, periksa langkah instalasi."
        exit 1
    fi

    # Jalankan sfoundryup
    echo "Menjalankan sfoundryup..."
    sfoundryup

    # Clone repository SeismicSystems/try-devnet jika belum ada
    if [ ! -d "try-devnet" ]; then
        echo "Mengkloning repository SeismicSystems/try-devnet..."
        git clone --recurse-submodules https://github.com/SeismicSystems/try-devnet.git
    else
        echo "Repository try-devnet sudah ada, melewati proses kloning."
    fi
    cd try-devnet/packages/contract/

    # Jalankan skrip deploy
    echo "Menjalankan skrip deploy kontrak..."
    bash script/deploy.sh

    # Tunggu input sebelum kembali ke menu utama
    echo "Deploy kontrak selesai, tekan tombol apa saja untuk kembali ke menu utama..."
    read -n 1 -s
}

# Fungsi untuk interaksi dengan kontrak
interaksi_kontrak() {
    echo "Memulai interaksi dengan kontrak..."
    
    # Instal Bun
    echo "Menginstal Bun..."
    curl -fsSL https://bun.sh/install | bash
    
    # Pastikan Bun tersedia
    source ~/.bashrc  # Perbarui lingkungan shell
    
    # Instal dependensi dengan Bun
    echo "Menginstal dependensi Bun..."
    cd /root/try-devnet/packages/cli/
    bun install
    
    # Jalankan skrip transaksi
    echo "Menjalankan skrip interaksi kontrak..."
    bash script/transact.sh

    # Tunggu input sebelum kembali ke menu utama
    echo "Interaksi kontrak selesai, tekan tombol apa saja untuk kembali ke menu utama..."
    read -n 1 -s
}

# Jalankan menu utama
menu_utama
