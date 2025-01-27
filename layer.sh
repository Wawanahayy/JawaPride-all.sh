#!/bin/bash

# Lokasi penyimpanan skrip
SCRIPT_PATH="$HOME/layeredge.sh"

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        echo "Skrip ini ditulis oleh komunitas Dadu Besar Hahahaha, Twitter @ferdie_jhovie, open source gratis, jangan percayai yang berbayar"
        echo "Jika ada masalah, dapat menghubungi Twitter, ini adalah satu-satunya akun"
        echo "================================================================"
        echo "Untuk keluar dari skrip, tekan ctrl + C pada keyboard"
        echo "Pilih operasi yang ingin dijalankan:"
        echo "1. Deploy node layeredge"
        echo "2. Keluar dari skrip"
        echo "================================================================"
        read -p "Masukkan pilihan (1/2): " choice

        case $choice in
            1)  deploy_layeredge_node ;;
            2)  exit ;;
            *)  echo "Pilihan tidak valid, silakan coba lagi!"; sleep 2 ;;
        esac
    done
}

# Memeriksa dan menginstal dependensi lingkungan
function install_dependencies() {
    echo "Memeriksa dependensi lingkungan sistem..."

    # Memeriksa dan menginstal git
    if ! command -v git &> /dev/null; then
        echo "Git tidak ditemukan, menginstal git..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y git
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        elif command -v brew &> /dev/null; then
            brew install git
        else
            echo "Tidak bisa menginstal git secara otomatis, silakan install git secara manual dan coba lagi."
            exit 1
        fi
        echo "Git telah terinstal!"
    else
        echo "Git sudah terinstal."
    fi

    # Memeriksa dan menginstal node dan npm
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        echo "Node atau npm tidak ditemukan, menginstal node dan npm..."
        if command -v apt-get &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif command -v yum &> /dev/null; then
            curl -fsSL https://rpm.nodesource.com/setup_16.x | sudo -E bash -
            sudo yum install -y nodejs
        elif command -v brew &> /dev/null; then
            brew install node
        else
            echo "Tidak bisa menginstal node dan npm secara otomatis, silakan install node dan npm secara manual dan coba lagi."
            exit 1
        fi
        echo "Node dan npm telah terinstal!"
    else
        echo "Node dan npm sudah terinstal."
    fi

    echo "Pemeriksaan dependensi lingkungan selesai!"
}

# Deploy node layeredge
function deploy_layeredge_node() {
    # Memeriksa dan menginstal dependensi lingkungan
    install_dependencies

    # Mengambil repositori
    echo "Mengambil repositori..."

    # Memeriksa apakah direktori tujuan sudah ada
    if [ -d "LayerEdge" ]; then
        echo "Direktori LayerEdge ditemukan."
        read -p "Apakah Anda ingin menghapus direktori lama dan menarik repositori lagi? (y/n) " delete_old
        if [[ "$delete_old" =~ ^[Yy]$ ]]; then
            echo "Menghapus direktori lama..."
            rm -rf LayerEdge
            echo "Direktori lama telah dihapus."
        else
            echo "Lewati pengambilan repositori, menggunakan direktori yang ada."
            read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
            return
        fi
    fi

    # Mengambil repositori
    if git clone https://github.com/sdohuajia/LayerEdge.git; then
        echo "Repositori berhasil diambil!"
    else
        echo "Pengambilan repositori gagal, silakan periksa koneksi jaringan atau alamat repositori."
        read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali ke menu utama..."
        main_menu
        return
    fi

    # Meminta pengguna untuk memasukkan alamat proxy
    echo "Masukkan alamat proxy (format seperti http://proxyuser:proxypass@127.0.0.1:8080), satu per satu, tekan enter untuk selesai:"
    > proxy.txt  # Mengosongkan atau membuat file proxy.txt
    while true; do
        read -p "Alamat proxy (tekan enter untuk selesai):" proxy
        if [ -z "$proxy" ]; then
            break  # Jika pengguna menekan enter, berhenti memasukkan
        fi
        echo "$proxy" >> proxy.txt  # Menulis alamat proxy ke proxy.txt
    done

    # Memeriksa apakah wallets.txt ada dan meminta konfirmasi untuk menimpanya
    echo "Memeriksa file konfigurasi wallet..."
    overwrite="no"
    if [ -f "wallets.txt" ]; then
        read -p "wallets.txt sudah ada, apakah Anda ingin memasukkan informasi wallet baru? (y/n) " overwrite
        if [[ "$overwrite" =~ ^[Yy]$ ]]; then
            rm -f wallets.txt
            echo "Informasi wallet lama telah dihapus, silakan masukkan informasi baru."
        else
            echo "Menggunakan file wallets.txt yang ada."
        fi
    fi

    # Memasukkan informasi wallet (jika perlu)
    if [ ! -f "wallets.txt" ] || [[ "$overwrite" =~ ^[Yy]$ ]]; then
        > wallets.txt  # Membuat atau mengosongkan file
        echo "Masukkan alamat wallet dan private key, format yang disarankan: alamat wallet, private key"
        echo "Masukkan satu wallet setiap kali, tekan enter untuk selesai:"
        while true; do
            read -p "Alamat wallet, private key (tekan enter untuk selesai):" wallet
            if [ -z "$wallet" ]; then
                if [ -s "wallets.txt" ]; then
                    break  # Jika file tidak kosong, izinkan untuk selesai
                else
                    echo "Anda harus memasukkan setidaknya satu alamat wallet dan private key yang valid!"
                    continue
                fi
            fi
            echo "$wallet" >> wallets.txt  # Menulis informasi wallet ke wallets.txt
        done
    fi

    # Masuk ke direktori
    echo "Masuk ke direktori proyek..."
    cd LayerEdge || {
        echo "Gagal masuk ke direktori, silakan periksa apakah repositori berhasil diambil."
        read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali ke menu utama..."
        main_menu
        return
    }

    # Menginstal dependensi
    echo "Menginstal dependensi menggunakan npm..."
    if npm install; then
        echo "Dependensi berhasil diinstal!"
    else
        echo "Gagal menginstal dependensi, silakan periksa koneksi jaringan atau konfigurasi npm."
        read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali ke menu utama..."
        main_menu
        return
    fi

    # Menyampaikan ke pengguna bahwa operasi selesai
    echo "Operasi selesai! Proxy telah disimpan di proxy.txt, wallet telah disimpan di wallets.txt, dependensi telah diinstal."

    # Menjalankan proyek
    echo "Menjalankan proyek..."
    screen -S layer -dm bash -c "cd ~/LayerEdge && npm start"  # Menjalankan npm start dalam sesi screen
    echo "Proyek telah dijalankan dalam sesi screen."
    echo "Anda dapat menggunakan perintah berikut untuk melihat status running:"
    echo "screen -r layer"
    echo "Jika perlu keluar dari sesi screen tanpa menghentikan proses, tekan Ctrl + A, lalu tekan tombol D."

    # Mengarahkan pengguna untuk kembali ke menu utama
    read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali ke menu utama..."
    main_menu
}

# Memanggil fungsi menu utama
main_menu
