#!/bin/bash

# Mendefinisikan logo
logo="🌟 Jawa Pride Airdrop 🌟"

# Define the loading_step function in Bash
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

# Fungsi welcome_message untuk menampilkan pesan dengan warna
welcome_message() {
    local message="Welcome to JAWA PRIDE AIRDROP SCRIPT { https://t.me/AirdropJP_JawaPride }"
    local colors=("31" "32" "33" "34" "35" "36")
    local color
    local counter=0
    
    # Menampilkan logo di baris pertama
    echo -e "\033[1;37m$logo\033[0m"
    
    # Menampilkan pesan dengan warna yang berganti
    for i in {1..5}; do  # Display the message only for 5 seconds
        color=${colors[$((counter % ${#colors[@]}))]}  # Pilih warna berdasarkan langkah
        echo -ne "\033[${color}m$message\033[0m"  # Menampilkan pesan dengan warna baru
        sleep 1  # Delay 1 detik per tampilan
        echo -ne "\r"  # Memindahkan kursor ke awal baris
        counter=$((counter + 1))  # Update langkah
    done
}

# Menjalankan welcome_message hanya selama 5 detik
clear
welcome_message 

# Fungsi-fungsi tampilan dengan logo
glowing_text() {
    local message="Welcome to JAWA PRIDE AIRDROP SCRIPT"
    echo -e "\033[1;37m$logo: $message\033[0m"
    sleep 0.5
}

perspective_shift() {
    local message="Done Forget To join channel https://t.me/AirdropJP_JawaPride"
    echo -e "\033[1;37m$logo: $message\033[0m"
    sleep 0.5
}

color_gradient() {
    local message="Follow twitter @JAWAPRIDE_ID { https://x.com/JAWAPRIDE_ID }"
    echo -e "\033[1;37m$logo: $message\033[0m"
    sleep 0.5
}

random_line_move() {
    local message="More details https://linktr.ee/Jawa_Pride_ID"
    echo -e "\033[1;37m$logo: $message\033[0m"
    sleep 0.5
}

pixelated_glitch() {
    local message="thanks you"
    echo -e "\033[1;37m$logo: $message\033[0m"
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

# Run welcome_message first
clear
welcome_message

# Continue with other functions
loading_step
glowing_text
perspective_shift
color_gradient
random_line_move
pixelated_glitch
machine_sounds
progress_bar

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install dependencies
dependencies=("curl" "jq")
for dependency in "${dependencies[@]}"; do
    if ! dpkg -l | grep -q "$dependency"; then
        echo "$dependency is not installed. Installing..."
        sudo apt install "$dependency" -y
    else
        echo "$dependency is already installed."
    fi
done

# Prompt for user input (email and password)
echo "Please enter your email:"
read -r email

echo "Please enter your password:"
read -s password

# Make the API request to login and get the token
response=$(curl -s -X POST "https://pipe-network-backend.pipecanary.workers.dev/api/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\", \"password\":\"$password\"}")

echo "Login response: $response"
echo "$(echo $response | jq -r .token)" > token.txt

log_file="node_operations.log"

# Function to fetch the public IP address
fetch_ip_address() {
    ip_response=$(curl -s "https://api64.ipify.org?format=json")
    echo "$(echo $ip_response | jq -r .ip)"
}

# Function to fetch the geo-location of the IP address
fetch_geo_location() {
    ip=$1
    geo_response=$(curl -s "https://ipapi.co/${ip}/json/")
    echo "$geo_response"
}

# Function to send heartbeat data
send_heartbeat() {
    token=$(cat token.txt)
    username="your_username"
    ip=$(fetch_ip_address)
    geo_info=$(fetch_geo_location "$ip")

    heartbeat_data=$(jq -n --arg username "$username" --arg ip "$ip" --argjson geo_info "$geo_info" \
        '{username: $username, ip: $ip, geo: $geo_info}')

    heartbeat_response=$(curl -s -X POST "https://pipe-network-backend.pipecanary.workers.dev/api/heartbeat" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$heartbeat_data")

    echo "Heartbeat response: $heartbeat_response" | tee -a "$log_file"
}

# Fetch points
fetch_points() {
    token=$(cat token.txt)
    points_response=$(curl -s -X GET "https://pipe-network-backend.pipecanary.workers.dev/api/points" \
        -H "Authorization: Bearer $token")

    if echo "$points_response" | jq -e . >/dev/null 2>&1; then
        echo "User Points Response: $points_response" | tee -a "$log_file"
    else
        echo "Error fetching points: $points_response" | tee -a "$log_file"
    fi
}

# Test nodes
test_nodes() {
    token=$(cat token.txt)
    nodes_response=$(curl -s -X GET "https://pipe-network-backend.pipecanary.workers.dev/api/nodes" \
        -H "Authorization: Bearer $token")

    if [ -z "$nodes_response" ]; then
        echo "Error: No nodes found or failed to fetch nodes." | tee -a "$log_file"
        return
    fi

    for node in $(echo "$nodes_response" | jq -c '.[]'); do
        node_id=$(echo "$node" | jq -r .node_id)
        node_ip=$(echo "$node" | jq -r .ip)

        latency=$(test_node_latency "$node_ip")

        if [[ "$latency" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            echo "Node ID: $node_id, IP: $node_ip, Latency: ${latency}ms" | tee -a "$log_file"
        else
            echo "Node ID: $node_id, IP: $node_ip, Latency: Timeout/Error" | tee -a "$log_file"
        fi

        report_test_result "$node_id" "$node_ip" "$latency"
    done
}

# Test latency for a node
test_node_latency() {
    node_ip=$1
    start=$(date +%s%3N)

    latency=$(curl -o /dev/null -s -w "%{time_total}\n" "http://$node_ip")

    if [ -z "$latency" ]; then
        return -1
    else
        echo $latency
    fi
}

# Report test results for a node
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
        echo "Node $node_id ($node_ip) reported successfully." | tee -a "$log_file"
    else
        echo "Failed to report node $node_id ($node_ip)." | tee -a "$log_file"
    fi
}

# Send heartbeat every minute
while true; do
    send_heartbeat
    sleep 60
done
