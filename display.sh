#!/bin/bash

# Fungsi untuk mencetak teks berwarna
print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

# Fungsi untuk menampilkan teks berwarna di bagian atas skrip
display_colored_text() {
    print_colored "42;37" "============================================================"  # Latar belakang hijau, teks putih
    print_colored "46;30" "=======================  J.W.P.A  ==========================" # Latar belakang cyan, teks hitam
    print_colored "45;97" "================= @AirdropJP_JawaPride =====================" # Latar belakang magenta, teks putih
    print_colored "43;30" "=============== https://x.com/JAWAPRIDE_ID =================" # Latar belakang kuning, teks hitam
    print_colored "41;97" "============= https://linktr.ee/Jawa_Pride_ID =============="  # Latar belakang merah, teks putih
    print_colored "44;30" "============================================================" # Latar belakang biru, teks hitam
}

# Tampilkan teks berwarna dan beri jeda
display_colored_text
sleep 5

# Fungsi untuk mencetak log
log() {
    local level=$1
    local message=$2
    echo "[$level] $message"
}

# Pertanyaan untuk bergabung dengan channel
while true; do
    read -p "Apakah Anda sudah bergabung dengan channel kami Channel: @AirdropJP_JawaPride? (y/n): " join_channel
    if [[ "$join_channel" == "y" || "$join_channel" == "Y" ]]; then
        break
    elif [[ "$join_channel" == "n" || "$join_channel" == "N" ]]; then
        echo "Silakan bergabung dengan channel terlebih dahulu."
        exit 1
    else
        echo "Pilihan tidak valid. Harap masukkan 'y' atau 'n'."
    fi
done

# Menggunakan curl untuk menampilkan informasi dari URL tertentu (contoh)
URL="https://api.example.com/data"
response=$(curl -s "$URL")
if [[ $? -eq 0 ]]; then
    log "INFO" "Data berhasil diambil dari $URL"
    echo "Response: $response"
else
    log "ERROR" "Gagal mengambil data dari $URL"
fi
