#!/bin/bash

# Step 1: Download the CLI
echo "Downloading Titan Edge CLI..."
wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.20/titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz -O titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz

# Step 2: Extract the downloaded package
echo "Extracting the downloaded package..."
tar -zxvf titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz

# Step 3: Enter the extracted folder
echo "Entering the extracted folder..."
cd titan-edge_v0.1.20_246b9dd_linux-amd64

# Step 4: Install Titan Edge executable
echo "Copying titan-edge executable to /usr/local/bin..."
sudo cp titan-edge /usr/local/bin

# Step 5: Install the library
echo "Copying libgoworkerd.so to /usr/local/lib..."
sudo cp libgoworkerd.so /usr/local/lib

# Step 6: Set up the library path
echo "Setting up library path..."
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

# Step 7: Start the Titan Edge daemon
echo "Starting the Titan Edge daemon..."
titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0

# Step 8: Bind the identification code
read -p "Please enter your identification code: " IDENTIFICATION_CODE
titan-edge bind --hash=$IDENTIFICATION_CODE https://api-test1.container1.titannet.io/api/v2/device/binding

# Step 9: Notify completion
echo "Installation and binding complete. Titan Edge is running."
