#!/bin/bash

# Function for loading message and running the script
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

# Function to display a welcome message with changing colors
welcome_message() {
    local message="Welcome to JAWA PRIDE AIRDROP SCRIPT { https://t.me/AirdropJP_JawaPride }"
    local colors=("31" "32" "33" "34" "35" "36")  # Colors for text
    local color
    local counter=0
    
    # Print message once without newline
    echo -n "$message"  # Print message once without newline

    # Change the color of the message in place
    for i in {1..10}; do  # Loop for 10 iterations (or however many you want)
        color=${colors[$((counter % ${#colors[@]}))]}  # Select color
        echo -ne "\033[${color}m$message\033[0m"  # Change the color of the message
        sleep 0.5  # Pause for effect
        echo -ne "\r"  # Return the cursor to the beginning of the line
        counter=$((counter + 1))  # Increment counter for color change
    done
}

# Other functions can remain the same
glowing_text() {
    logo="Logo"
    echo -e "\033[1;37m$logo\033[0m"
    sleep 0.5
}

# Function to test connectivity and latency for nodes
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

# Function to test latency for a node
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

# Run the functions
clear
welcome_message  # Call the welcome message function

# Continue with other functions
loading_step
glowing_text
test_nodes
send_heartbeat
