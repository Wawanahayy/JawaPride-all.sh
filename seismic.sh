#!/bin/bash

# One Click Deployment Script for Seismic Devnet
# Author: ChatGPT 🥷💻

echo "🚀 Starting One-Click Deployment for Seismic Devnet..."

# Install Rust
echo "🔧 Installing Rust..."
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

# Install jq (Mac)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍏 Installing jq for Mac..."
    brew install jq
else
    echo "🔍 Please install jq manually for your OS: https://stedolan.github.io/jq/download/"
fi

# Install sfoundryup
echo "📦 Installing sfoundryup..."
curl -L -H "Accept: application/vnd.github.v3.raw" \
     "https://api.github.com/repos/SeismicSystems/seismic-foundry/contents/sfoundryup/install?ref=seismic" | bash
source ~/.bashrc

# Run sfoundryup (this may take a while)
echo "⏳ Running sfoundryup... (this may take 5m to 60m)"
sfoundryup

# Clone the repository
echo "📂 Cloning the Seismic Devnet repository..."
git clone --recurse-submodules https://github.com/SeismicSystems/try-devnet.git
cd try-devnet/packages/contract/

# Deploy the contract
echo "🚀 Deploying the encrypted contract..."
bash script/deploy.sh

# Install Bun
echo "📦 Installing Bun..."
curl -fsSL https://bun.sh/install | bash

# Install Node dependencies
echo "📂 Installing Node dependencies..."
cd ../cli/
bun install

# Ready to interact
echo "✅ Deployment complete! You can now interact with your contract using:"
echo "bash script/transact.sh"
