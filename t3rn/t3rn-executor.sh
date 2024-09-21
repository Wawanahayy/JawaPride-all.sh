#!/bin/bash

# Function to print colored text
print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

# Function to display the banner with colored text
display_colored_text() {
    print_colored "42;30" "========================================================="
    print_colored "46;30" "========================================================="
    print_colored "45;97" "======================   T3EN   ========================="
    print_colored "43;30" "============== create all by JAWA-PRIDE  ================"
    print_colored "41;97" "=========== https://t.me/AirdropJP_JawaPride ============"
    print_colored "44;30" "========================================================="
    print_colored "42;97" "========================================================="
}

# Display the colored banner
display_colored_text
sleep 5

# Log function to print messages with different levels
log() {
    local level=$1
    local message=$2
    echo "[$level] $message"
}

# Pertanyaan untuk bergabung dengan channel Telegram
read -p "Apakah Anda sudah bergabung dengan channel kami Channel: @AirdropJP_JawaPride https://t.me/AirdropJP_JawaPride? (y/n): " join_channel

if [[ "$join_channel" == "y" || "$join_channel" == "Y" ]]; then
    echo "Terima kasih telah bergabung dengan channel kami!"
else
    echo "Kami sarankan Anda bergabung dengan channel untuk mendapatkan informasi terbaru."
    sleep 5
    exit 1
fi

# System update and binary download as before
sleep 1
cd $HOME
rm -rf executor
sudo apt -q update
sudo apt -qy upgrade

EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/v0.21.1/executor-linux-v0.21.1.tar.gz"
EXECUTOR_FILE="executor-linux-v0.21.1.tar.gz"
echo "Downloading the Executor binary from $EXECUTOR_URL..."
curl -L -o $EXECUTOR_FILE $EXECUTOR_URL
if [ $? -ne 0 ]; then
    echo "Failed to download the Executor binary. Please check your internet connection and try again."
    exit 1
fi

echo "Extracting the binary..."
tar -xzvf $EXECUTOR_FILE
rm -rf $EXECUTOR_FILE
cd executor/executor/bin
echo "Binary downloaded and extracted successfully."
echo

# Set environment variables with new RPC URLs
export NODE_ENV=testnet
export LOG_LEVEL=debug
export LOG_PRETTY=false
export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn'

# Add your private key here
export PRIVATE_KEY_LOCAL="<your_private_key_here>"

# Check if the private key is set
if [[ -z "$PRIVATE_KEY_LOCAL" ]]; then
    echo "Error: PRIVATE_KEY_LOCAL is not set. Please provide a valid private key."
    exit 1
fi

export RPC_ENDPOINTS_ARBT='https://sepolia-rollup.arbitrum.io/rpc'
export RPC_ENDPOINTS_BSSP='https://sepolia.base.org/rpc'
export RPC_ENDPOINTS_BLSS='https://sepolia.blast.io/'
export RPC_ENDPOINTS_OPSP='https://optimism-sepolia.drpc.org'

sleep 1

# Start the executor
echo "Starting the Executor..."
./executor
if [ $? -ne 0 ]; then
    echo "Executor failed to start. Please check the logs for more details."
    exit 1
fi
