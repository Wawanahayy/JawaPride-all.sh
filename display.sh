#!/bin/bash

print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

display_colored_text() {
    print_colored "42;37" "============================================================"  
    print_colored "40;96" "=======================  J.W.P.A  ==========================" 
    print_colored "45;97" "================= @AirdropJP_JawaPride =====================" 
    print_colored "43;30" "=============== https://x.com/JAWAPRIDE_ID =================" 
    print_colored "41;97" "============= https://linktr.ee/Jawa_Pride_ID ==============" 
    print_colored "44;30" "============================================================" 
}

display_colored_text
sleep 5

log() {
    local level=$1
    local message=$2
    echo "[$level] $message"
}

# Pertanyaan untuk bergabung dengan channel
while true; do
    read -p "Apakah Anda sudah bergabung dengan channel kami Channel: @AirdropJP_JawaPride? (y/n): " join_channel
    echo "Input: $join_channel"  # Menampilkan input untuk debug
    case "$join_channel" in
        [yY]* ) 
            echo "Terima kasih telah bergabung!"
            break 
            ;;
        [nN]* ) 
            echo "Silakan bergabung dengan channel terlebih dahulu." && exit 1 
            ;;
        * ) 
            echo "Pilihan tidak valid. Harap masukkan 'y' atau 'n'." 
            ;;
    esac
done

