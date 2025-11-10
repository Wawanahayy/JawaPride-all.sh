#!/usr/bin/env bash
set -euo pipefail

#############################################
# Stable Testnet one-click installer (clean)
#############################################

CHAIN_ID="stabletestnet_2201-1"
BINARY_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/stabled-latest-linux-amd64-testnet.tar.gz"
GENESIS_ZIP_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/stable_testnet_genesis.zip"
CONFIG_ZIP_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/rpc_node_config.zip"
SNAPSHOT_URL="https://stable-snapshot.s3.eu-central-1.amazonaws.com/snapshot.tar.lz4"

HOME_DIR="$HOME"
CONFIG_DIR="$HOME_DIR/.stabled/config"
DATA_DIR="$HOME_DIR/.stabled/data"
SERVICE_NAME="stabled"
USER_NAME="$(whoami)"

# -------- Optional display step (banner) --------
loading_step() {
    echo "Downloading and running display script..."
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash || echo "Display script failed (optional)."
    echo
}

loading_step

echo "=========================================="
echo " Stable Testnet one-click setup (CLEAN)"
echo " Chain ID: $CHAIN_ID"
echo "=========================================="
echo

# -------- Input section --------
read -rp "Node moniker (name, e.g. Jawa Pride): " MONIKER
if [ -z "${MONIKER}" ]; then
  MONIKER="stable-node"
fi

read -rp "Use fast snapshot for quick sync? (y/N): " USE_SNAPSHOT
USE_SNAPSHOT=${USE_SNAPSHOT:-N}

read -rp "Configure UFW firewall automatically? (y/N): " USE_UFW
USE_UFW=${USE_UFW:-N}

read -rp "Open RPC ports 26657 / 8545 / 8546 if UFW is enabled? (y/N): " OPEN_RPC
OPEN_RPC=${OPEN_RPC:-N}

echo
echo "== Summary =="
echo "Moniker         : $MONIKER"
echo "Fast snapshot   : $USE_SNAPSHOT"
echo "Auto UFW config : $USE_UFW"
echo "Open RPC ports  : $OPEN_RPC"
echo

read -rp "Proceed with CLEAN installation? (y/N): " CONFIRM
CONFIRM=${CONFIRM:-N}
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Aborted."
  exit 1
fi

# -------- 0. Stop old service & optional FULL reset --------
echo
echo ">>> Step 0: Stopping old service & optional reset..."

if systemctl list-units --full -all 2>/dev/null | grep -q "^${SERVICE_NAME}.service"; then
  echo "Stopping existing systemd service: ${SERVICE_NAME}"
  sudo systemctl stop "${SERVICE_NAME}" || true
fi

read -rp "Full reset ~/.stabled (backup then delete)? (y/N): " RESET_DATA
RESET_DATA=${RESET_DATA:-N}

if [ "$RESET_DATA" = "y" ] || [ "$RESET_DATA" = "Y" ]; then
  TS="$(date +%Y%m%d-%H%M%S)"
  if [ -d "$HOME_DIR/.stabled" ]; then
    echo "Backing up existing ~/.stabled to ~/stabled-backup-${TS}"
    cp -a "$HOME_DIR/.stabled" "$HOME_DIR/stabled-backup-${TS}"
  fi
  echo "Removing ~/.stabled for fresh setup..."
  rm -rf "$HOME_DIR/.stabled"
else
  echo "Keeping existing ~/.stabled directory (no full reset)."
fi

echo "Cleaning old install artifacts in \$HOME (genesis/config/tar/zip)..."
rm -f \
  "$HOME_DIR/genesis.json" \
  "$HOME_DIR/config.toml" \
  "$HOME_DIR/app.toml" \
  "$HOME_DIR/stable_testnet_genesis.zip" \
  "$HOME_DIR/rpcnode_config.zip" \
  "$HOME_DIR/stabled-latest-linux-amd64-testnet.tar.gz" \
  "$HOME_DIR"/stabled-*-testnet-linux-amd64.tar.gz 2>/dev/null || true

# -------- 1. Update OS + install packages --------
echo
echo ">>> Step 1: Updating OS and installing packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git wget curl jq lz4 zstd unzip htop net-tools ufw pv perl

# -------- 2. Download + install binary --------
echo
echo ">>> Step 2: Downloading and installing stabled binary..."
cd "$HOME_DIR"

wget "$BINARY_URL" -O stabled-latest-linux-amd64-testnet.tar.gz
tar -xvzf stabled-latest-linux-amd64-testnet.tar.gz

sudo mv stabled /usr/bin/stabled
sudo chmod +x /usr/bin/stabled

echo
echo "stabled version:"
stabled version || echo "Warning: cannot show version (check binary name/path)."

# -------- 3. Init node --------
echo
echo ">>> Step 3: Initializing node..."
stabled init "$MONIKER" --chain-id "$CHAIN_ID"

mkdir -p "$CONFIG_DIR"

# -------- 4. Genesis --------
echo
echo ">>> Step 4: Downloading genesis..."
if [ -f "$CONFIG_DIR/genesis.json" ]; then
  mv "$CONFIG_DIR/genesis.json" "$CONFIG_DIR/genesis.json.backup.$(date +%s)" || true
fi

cd "$HOME_DIR"
wget "$GENESIS_ZIP_URL" -O stable_testnet_genesis.zip
unzip -o stable_testnet_genesis.zip

cp -f genesis.json "$CONFIG_DIR/genesis.json"

echo
echo "Genesis checksum:"
sha256sum "$CONFIG_DIR/genesis.json"

# -------- 5. config.toml (P2P + RPC) --------
echo
echo ">>> Step 5: Applying recommended config (config.toml)..."
cd "$HOME_DIR"
wget "$CONFIG_ZIP_URL" -O rpcnode_config.zip
unzip -o rpcnode_config.zip

if [ -f "$CONFIG_DIR/config.toml" ]; then
  cp -f "$CONFIG_DIR/config.toml" "$CONFIG_DIR/config.toml.backup.$(date +%s)" || true
fi

cp -f config.toml "$CONFIG_DIR/config.toml"

# Escape moniker untuk TOML
ESCAPED_MONIKER=$(printf '%s\n' "$MONIKER" | sed 's/[&/\\]/\\&/g')
sed -i "s/^moniker = \".*\"/moniker = \"${ESCAPED_MONIKER}\"/" "$CONFIG_DIR/config.toml" || true

echo "Tweaking P2P + RPC in config.toml..."
sed -i 's/^max_num_inbound_peers *=.*/max_num_inbound_peers = 50/' "$CONFIG_DIR/config.toml" || true
sed -i 's/^max_num_outbound_peers *=.*/max_num_outbound_peers = 30/' "$CONFIG_DIR/config.toml" || true
sed -i 's|^persistent_peers *=.*|persistent_peers = "5ed0f977a26ccf290e184e364fb04e268ef16430@37.187.147.27:26656,128accd3e8ee379bfdf54560c21345451c7048c7@37.187.147.22:26656"|' "$CONFIG_DIR/config.toml" || true
sed -i 's/^pex *=.*/pex = true/' "$CONFIG_DIR/config.toml" || true
sed -i 's|^laddr *= .*|laddr = "tcp://0.0.0.0:26657"|' "$CONFIG_DIR/config.toml" || true
sed -i 's/^max_open_connections *=.*/max_open_connections = 900/' "$CONFIG_DIR/config.toml" || true

# Try to set external_address with detected IP later (after we detect PUBLIC_IP)

# NOTE: we TIDAK ngoprek [json-rpc] di app.toml lagi di sini, biar aman dari error TOML.
# Kalau mau buka JSON-RPC ke publik, nanti bisa edit ~/.stabled/config/app.toml manual.

# -------- 6. Snapshot (optional) --------
if [ "$USE_SNAPSHOT" = "y" ] || [ "$USE_SNAPSHOT" = "Y" ]; then
  echo
  echo ">>> Step 6: Fast sync via snapshot..."
  mkdir -p "$HOME_DIR/snapshot"
  cd "$HOME_DIR/snapshot"

  mkdir -p "$DATA_DIR"
  rm -rf "$DATA_DIR"/*

  wget -c "$SNAPSHOT_URL" -O snapshot.tar.lz4
  echo "Extracting snapshot to $HOME_DIR/.stabled ..."
  pv snapshot.tar.lz4 | tar -I lz4 -xf - -C "$HOME_DIR/.stabled"
else
  echo
  echo ">>> Step 6: Skipping snapshot, node will sync from scratch."
fi

# -------- 7. Firewall (UFW) --------
if [ "$USE_UFW" = "y" ] || [ "$USE_UFW" = "Y" ]; then
  echo
  echo ">>> Step 7: Configuring UFW firewall..."
  sudo ufw allow 22/tcp
  sudo ufw allow 26656/tcp

  if [ "$OPEN_RPC" = "y" ] || [ "$OPEN_RPC" = "Y" ]; then
    sudo ufw allow 26657/tcp
    sudo ufw allow 8545/tcp
    sudo ufw allow 8546/tcp
  fi

  sudo ufw --force enable
else
  echo
  echo ">>> Step 7: Skipping UFW auto configuration."
  echo "You can manually run (if needed):"
  echo "  sudo ufw allow 22/tcp"
  echo "  sudo ufw allow 26656/tcp"
  echo "  sudo ufw allow 26657/tcp  # if you need public RPC"
  echo "  sudo ufw allow 8545/tcp   # if you need public JSON-RPC"
  echo "  sudo ufw allow 8546/tcp   # if you need public WS"
  echo "  sudo ufw enable"
fi

# -------- 8. systemd service --------
echo
echo ">>> Step 8: Creating systemd service..."

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=Stable Daemon Service
After=network-online.target

[Service]
User=${USER_NAME}
ExecStart=/usr/bin/stabled start --chain-id ${CHAIN_ID}
Restart=always
RestartSec=3
LimitNOFILE=65535
StandardOutput=journal
StandardError=journal
SyslogIdentifier=stabled

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}"

echo
echo ">>> Service status:"
sudo systemctl status "${SERVICE_NAME}" --no-pager || true

# -------- 9. Detect public IP & print endpoints --------
echo
PUBLIC_IP="$(curl -s https://ifconfig.me || echo "")"
if [ -z "$PUBLIC_IP" ]; then
  PUBLIC_IP="<YOUR_IP>"
else
  # Set external_address in config.toml when we know IP
  if [ -f "$CONFIG_DIR/config.toml" ]; then
    sed -i "s|^external_address *=.*|external_address = \"${PUBLIC_IP}:26656\"|" "$CONFIG_DIR/config.toml" || true
  fi
fi

echo "=========================================="
echo " Stable node setup finished."
echo " Moniker        : $MONIKER"
echo " Chain ID       : $CHAIN_ID"
echo " Data dir       : $HOME_DIR/.stabled"
echo " Service        : ${SERVICE_NAME}"
echo "=========================================="
echo
echo "Useful commands:"
echo "  sudo journalctl -u stabled -f"
echo "  curl -s localhost:26657/status | jq '.result.sync_info'"
echo "  curl -s localhost:26657/net_info | jq '.result.n_peers'"
echo

echo "Detected IP      : ${PUBLIC_IP}"
echo "Tendermint RPC   : http://${PUBLIC_IP}:26657"
echo "JSON-RPC (EVM)   : http://${PUBLIC_IP}:8545   (enable in app.toml if needed)"
echo "WS JSON-RPC      : ws://${PUBLIC_IP}:8546    (enable in app.toml if needed)"
echo
echo "If you ever need a hard reset:"
echo "  stabled comet unsafe-reset-all"
echo
echo "Done."
