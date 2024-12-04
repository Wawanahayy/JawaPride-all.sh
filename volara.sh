#!/bin/bash

# Skrip Otomatisasi: Instalasi dan Jalankan Volara-Miner

# Definisi kode warna
MERAH='\033[0;31m'
HIJAU='\033[0;32m'
KUNING='\033[1;33m'
BIRU='\033[0;34m'
CYAN='\033[0;36m'
TEBAL='\033[1m'
GARIS_BAWAH='\033[4m'
RESET='\033[0m'

# Definisi ikon
INFO_ICON="ℹ️"
SUKSES_ICON="✅"
PERINGATAN_ICON="⚠️"
ERROR_ICON="❌"

# Fungsi untuk menampilkan informasi
log_info() {
  echo -e "${CYAN}${INFO_ICON} ${1}${RESET}"
}

log_success() {
  echo -e "${HIJAU}${SUKSES_ICON} ${1}${RESET}"
}

log_warning() {
  echo -e "${KUNING}${PERINGATAN_ICON} ${1}${RESET}"
}

log_error() {
  echo -e "${MERAH}${ERROR_ICON} ${1}${RESET}"
}

# Fungsi: Update dan upgrade sistem
update_system() {
  log_info "Sedang memperbarui dan meng-upgrade sistem..."
  sudo apt update -y && sudo apt upgrade -y
}

# Fungsi: Instal Docker
install_docker() {
  log_info "Sedang menginstal Docker dan dependensinya..."
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo chmod +x /usr/local/bin/docker-compose

  docker --version &> /dev/null
  if [[ $? -eq 0 ]]; then
    log_success "Docker berhasil diinstal."
  else
    log_error "Gagal menginstal Docker."
    exit 1
  fi
}

# Fungsi: Jalankan Volara-Miner
start_miner() {
  log_info "Pastikan dompet jaringan Vana Anda memiliki cukup token uji. Kunjungi faucet: https://faucet.vana.org/moksha untuk klaim token uji."
  echo -e "${KUNING}Tips: Periksa saldo jaringan Vana Anda sebelum melanjutkan.${RESET}"
  
  read -sp "$(echo -e "${KUNING}Masukkan kunci privat Metamask Anda (tidak akan ditampilkan di layar): ${RESET}")" VANA_PRIVATE_KEY
  export VANA_PRIVATE_KEY

  if [[ -z "$VANA_PRIVATE_KEY" ]]; then
    log_error "Kunci privat Metamask tidak boleh kosong. Jalankan ulang skrip ini dan masukkan kunci privat yang valid."
    exit 1
  fi

  log_info "Sedang menarik gambar Docker Volara-Miner..."
  docker pull volara/miner
  if [[ $? -eq 0 ]]; then
    log_success "Gambar Docker Volara-Miner berhasil ditarik."
  else
    log_error "Gagal menarik gambar Docker Volara-Miner."
    exit 1
  fi

  log_info "Sedang membuat sesi Screen..."
  screen -S volara -m bash -c "docker run -it -e VANA_PRIVATE_KEY=${VANA_PRIVATE_KEY} volara/miner"

  log_info "Sambungkan secara manual ke sesi Screen: screen -r volara"
  log_info "Dalam sesi Screen, ikuti instruksi di layar untuk menyelesaikan autentikasi Google dan login akun X."

  log_success "Pengaturan selesai! Anda dapat memantau skor mining Anda di https://volara.xyz/."
}

# Fungsi: Lihat log Volara-Miner
view_miner_logs() {
  clear
  log_info "Menampilkan log Volara-Miner yang berjalan..."
  docker ps --filter "ancestor=volara/miner" --format "{{.Names}}" | while read container_name
  do
    echo "Log dari container: $container_name"
    docker logs --tail 20 "$container_name"
    echo "--------------------------------------"
  done
}

# Fungsi: Menu utama
show_menu() {
  clear
  # Menampilkan logo setiap kali menu ditampilkan
  curl -m 5 -s curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
  echo -e "\n${TEBAL}${BIRU}==================== Pengaturan Volara-Miner ====================${RESET}"
  echo "1. Update dan upgrade sistem"
  echo "2. Instal Docker"
  echo "3. Jalankan Volara-Miner"
  echo "4. Lihat log Volara-Miner"
  echo "5. Keluar"
  echo -e "${TEBAL}===============================================================${RESET}"
  echo -n "Pilih opsi [1-5]: "
}

# Loop utama
while true; do
  show_menu
  read -r choice
  case $choice in
    1)
      update_system
      ;;
    2)
      install_docker
      ;;
    3)
      start_miner
      ;;
    4)
      view_miner_logs
      ;;
    5)
      log_info "Keluar dari skrip, sampai jumpa!"
      exit 0
      ;;
    *)
      log_warning "Pilihan tidak valid. Silakan pilih opsi yang valid."
      ;;
  esac
done
