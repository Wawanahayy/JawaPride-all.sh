#!/bin/bash

# Define functions first
loading_step() {
    echo "Mengunduh dan menjalankan skrip display..."
    
    url="https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh"
    # Download and run the script
    curl -s -o display.sh "$url"
    if [[ $? -eq 0 ]]; then
        bash display.sh
    else
        echo "Error saat mengunduh skrip."
    fi
}

welcome_message() {
    local message="Welcome to JAWA PRIDE AIRDROP SCRIPT { https://t.me/AirdropJP_JawaPride }"
    local colors=("31" "32" "33" "34" "35" "36")
    local color
    local counter=0
    
    # Ulangi beberapa kali dalam satu print (mengubah warna tanpa mencetak ulang pesan)
    while true; do
        color=${colors[$((counter % ${#colors[@]}))]}  # Pilih warna berdasarkan langkah
        echo -ne "\033[${color}m$message\033[0m"  # Menampilkan pesan dengan warna baru
        sleep 0.5  # Delay setengah detik untuk memberikan efek kedip
        echo -ne "\r"  # Memindahkan kursor ke awal baris
        counter=$((counter + 1))  # Update langkah
    done
}

# Other functions like glowing_text, perspective_shift, etc.
glowing_text() {
    logo="Welcome to JAWA PRIDE AIRDROP SCRIPT "
    echo -e "\033[1;37m$logo\033[0m"
    sleep 0.5
}

perspective_shift() {
    logo="Done Forget To join channel https://t.me/AirdropJP_JawaPride"
    echo -e "\033[1;37m$logo\033[0m"
    sleep 0.5
}

color_gradient() {
    logo="Follow twitter @JAWAPRIDE_ID { https://x.com/JAWAPRIDE_ID }"
    echo -e "\033[1;37m$logo\033[0m"
    sleep 0.5
}

random_line_move() {
    logo="More details https://linktr.ee/Jawa_Pride_ID"
    echo -e "\033[1;37m$logo\033[0m"
    sleep 0.5
}

pixelated_glitch() {
    logo="thanks you"
    echo -e "\033[1;37m$logo\033[0m"
    sleep 2
}

machine_sounds() {
    for i in {1..3}; do
        echo -e "\a"
        sleep 0.3
        echo -e "\033[1;32m*Whirr* \033[0m"
        sleep 0.5
    done
}

progress_bar() {
    echo -e "Loading... \033[1;34m[##########]\033[0m"
    sleep 0.5
}

fetch_ip_address() {
    ip_response=$(curl -s "https://api64.ipify.org?format=json")
    echo "$(echo $ip_response | jq -r .ip)"
}

fetch_geo_location() {
    ip=$1
    geo_response=$(curl -s "https://ipapi.co/${ip}/json/")
    echo "$geo_response"
}

send_heartbeat() {
    token=$(cat token.txt)
    username="your_username"
    ip=$(fetch_ip_address)
    geo_info=$(fetch_geo_location "$ip")

    heartbeat_data=$(jq -n --arg username "$username" --arg ip "$ip" --argjson geo_info "$geo_info" \
        '{username: $username, ip: $ip, geo: $geo_info}')

    echo "Heartbeat data: $heartbeat_data" | tee -a "$log_file"  # Debug print
    
    heartbeat_response=$(curl -s -X POST "https://pipe-network-backend.pipecanary.workers.dev/api/heartbeat" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$heartbeat_data")

    echo "Heartbeat response: $heartbeat_response" | tee -a "$log_file"
}

report_test_result() {
    node_id=$1
    node_ip=$2
    latency=$3

    token=$(cat token.txt)

    if [ -z "$token" ]; then
        echo "Error: No token found. Skipping result reporting." | tee -a "$log_file"
        return
    fi

    if [[ "$latency" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(echo "$latency > 0" | bc -l) )); then
        status="online"
    else
        status="offline"
        latency=-1
    fi

    report_response=$(curl -s -X POST "https://pipe-network-backend.pipecanary.workers.dev/api/test" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "{\"node_id\": \"$node_id\", \"ip\": \"$node_ip\", \"latency\": $latency, \"status\": \"$status\"}")

    if echo "$report_response" | jq -e . >/dev/null 2>&1; then
        echo "Reported result for node $node_id ($node_ip), status: $status" | tee -a "$log_file"
    else
        echo "Error reporting test result for node $node_id ($node_ip)" | tee -a "$log_file"
    fi
}

# Run the functions
clear
welcome_message
loading_step
glowing_text
perspective_shift
color_gradient
random_line_move
pixelated_glitch
machine_sounds
progress_bar

# Continue with other operations
send_heartbeat
