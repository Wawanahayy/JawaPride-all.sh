#!/bin/bash

# Clone the repository
git clone https://github.com/Wawanahayy/sui_meta_miner

# Navigate into the project directory
cd sui_meta_miner

# Install dependencies
npm install

# Install suidouble
npm install suidouble

# Display success message
echo "Sui Meta Miner setup completed successfully!"

chmod +x setup_sui_meta_miner.sh

./setup_sui_meta_miner.sh
