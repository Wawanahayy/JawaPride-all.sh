#!/usr/bin/env bash
set -euo pipefail

#############################################
# Stable Testnet one-click installer (FULL CLEAN)
#############################################

CHAIN_ID="stabletestnet_2201-1"
BINARY_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/stabled-latest-linux-amd64-testnet.tar.gz"
GENESIS_ZIP_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/stable_testnet_genesis.zip"
SNAPSHOT_URL="https://stable-snapshot.s3.eu-central-1.amazonaws.com/snapshot.tar.lz4"

HOME_DIR="$HOME"
CONFIG_DIR="$HOME_DIR/.stabled/config"
DATA_DIR="$HOME_DIR/.stabled/data"
SERVICE_NAME="stabled"
USER_NAME="$(whoami)"

# -------- Optional display step (external banner/script) --------
loading_step() {
    echo "Downloading and running display script..."
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash || echo "Display script failed (optional)."
    echo
}

# -------- Helper: detect public IP --------
detect_ip() {
    IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me || true)
    if [ -n "${IP:-}" ]; then
        echo "$IP"
        return
    fi

    IP_LOCAL=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -n "${IP_LOCAL:-}" ]; then
        echo "$IP_LOCAL"
        return
    fi

    echo "YOUR_IP"
}

loading_step

echo "=========================================="
echo " Stable Testnet one-click setup (FULL CLEAN)"
echo " Chain ID: $CHAIN_ID"
echo "=========================================="
echo

#############################################
# STEP 0: STOP & REMOVE PREVIOUS NODE
#############################################
echo ">>> Step 0: Stopping and removing previous node (if any)..."

# Stop and disable old systemd service if exists
if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
  echo "Found existing systemd service: ${SERVICE_NAME}.service"
  sudo systemctl stop "${SERVICE_NAME}" || true
  sudo systemctl disable "${SERVICE_NAME}" || true
  sudo rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
  sudo systemctl daemon-reload
  echo "Old systemd service removed."
else
  echo "No previous systemd service found for ${SERVICE_NAME}."
fi

# Optionally remove old binary
if command -v stabled >/dev/null 2>&1; then
  echo "Existing stabled binary detected at: $(command -v stabled)"
  read -rp "Remove existing stabled binary and replace with fresh one? (y/N): " RM_BIN
  RM_BIN=${RM_BIN:-N}
  if [ "$RM_BIN" = "y" ] || [ "$RM_BIN" = "Y" ]; then
    sudo rm -f "$(command -v stabled)" || true
    echo "Old stabled binary removed."
  else
    echo "Keeping existing stabled binary."
  fi
else
  echo "No existing stabled binary found in PATH."
fi

# Backup and remove old home dir
if [ -d "$HOME_DIR/.stabled" ]; then
  echo "Found existing directory: $HOME_DIR/.stabled"
  read -rp "Backup and DELETE it for a clean reinstall? (y/N): " RESET_HOME
  RESET_HOME=${RESET_HOME:-N}
  if [ "$RESET_HOME" = "y" ] || [ "$RESET_HOME" = "Y" ]; then
    TS=$(date +%Y%m%d-%H%M%S)
    BACKUP_DIR="$HOME_DIR/stabled-backup-$TS"
    echo "Backing up current .stabled to: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -a "$HOME_DIR/.stabled" "$BACKUP_DIR/" || true
    echo "Removing $HOME_DIR/.stabled ..."
    rm -rf "$HOME_DIR/.stabled"
  else
    echo "Keeping existing .stabled directory. If configs are corrupted, install may fail."
  fi
else
  echo "No previous ~/.stabled directory found."
fi

#############################################
# STEP 1: INPUTS
#############################################
read -rp "Node moniker (name, e.g. Jawa Pride): " MONIKER
if [ -z "${MONIKER}" ]; then
  MONIKER="stable-node"
fi

read -rp "Use fast snapshot for quick sync? (y/N): " USE_SNAPSHOT
USE_SNAPSHOT=${USE_SNAPSHOT:-N}

echo
echo "== Summary =="
echo "Moniker       : $MONIKER"
echo "Fast snapshot : $USE_SNAPSHOT"
echo

read -rp "Proceed with installation? (y/N): " CONFIRM
CONFIRM=${CONFIRM:-N}
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Aborted."
  exit 1
fi

#############################################
# STEP 2: PACKAGES
#############################################
echo
echo ">>> Step 1: Updating OS and installing packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git wget curl jq lz4 zstd unzip htop net-tools pv perl

#############################################
# STEP 3: BINARY
#############################################
echo
echo ">>> Step 2: Downloading and installing stabled binary..."
cd "$HOME_DIR"
if [ -f "stabled-latest-linux-amd64-testnet.tar.gz" ]; then
  rm -f stabled-latest-linux-amd64-testnet.tar.gz
fi

wget "$BINARY_URL" -O stabled-latest-linux-amd64-testnet.tar.gz
tar -xvzf stabled-latest-linux-amd64-testnet.tar.gz

sudo mv stabled /usr/bin/stabled
sudo chmod +x /usr/bin/stabled

echo
echo "stabled version (should be OK, no TOML error here):"
stabled version || echo "Warning: cannot show version (if TOML error appears here, old configs still exist in some other HOME)."

#############################################
# STEP 4: INIT NODE
#############################################
echo
echo ">>> Step 3: Initializing node..."
stabled init "$MONIKER" --chain-id "$CHAIN_ID"

mkdir -p "$CONFIG_DIR"

#############################################
# STEP 5: GENESIS
#############################################
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

#############################################
# STEP 6: CONFIG.TOML TWEAKS (minimal)
#############################################
echo
echo ">>> Step 5: Tweaking config.toml (moniker, peers, rpc)..."

CONFIG_TOML="$CONFIG_DIR/config.toml"

if [ -f "$CONFIG_TOML" ]; then
  cp -f "$CONFIG_TOML" "$CONFIG_TOML.backup.$(date +%s)" || true

  # Escape moniker for TOML
  ESCAPED_MONIKER=$(printf '%s\n' "$MONIKER" | sed 's/[&/\\]/\\&/g')
  sed -i "s/^moniker = \".*\"/moniker = \"${ESCAPED_MONIKER}\"/" "$CONFIG_TOML" || true

  # P2P peers & params
  sed -i 's/^max_num_inbound_peers *=.*/max_num_inbound_peers = 50/' "$CONFIG_TOML" || true
  sed -i 's/^max_num_outbound_peers *=.*/max_num_outbound_peers = 30/' "$CONFIG_TOML" || true
  sed -i 's|^persistent_peers *=.*|persistent_peers = "5ed0f977a26ccf290e184e364fb04e268ef16430@37.187.147.27:26656,128accd3e8ee379bfdf54560c21345451c7048c7@37.187.147.22:26656"|' "$CONFIG_TOML" || true
  sed -i 's/^pex *=.*/pex = true/' "$CONFIG_TOML" || true

  # RPC listen on all interfaces (Tendermint)
  sed -i 's|^laddr *= .*|laddr = "tcp://0.0.0.0:26657"|' "$CONFIG_TOML" || true
  sed -i 's/^max_open_connections *=.*/max_open_connections = 900/' "$CONFIG_TOML" || true
else
  echo "ERROR: $CONFIG_TOML not found after init. Something is wrong."
  exit 1
fi

#############################################
# STEP 7: SNAPSHOT (optional)
#############################################
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

#############################################
# STEP 8: SYSTEMD SERVICE
#############################################
echo
echo ">>> Step 7: Creating systemd service..."

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=Stable Daemon Service
After=network-online.target

[Service]
User=${USER_NAME}
ExecStart=/usr/bin/stabled start --chain-id ${CHAIN_ID} --rpc.laddr "tcp://0.0.0.0:26657" --json-rpc.enable=true --json-rpc.address "0.0.0.0:8545" --json-rpc.ws-address "0.0.0.0:8546" --json-rpc.allow-unprotected-txs=true
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

#############################################
# STEP 9: FINAL INFO
#############################################
PUBLIC_IP=$(detect_ip)

echo
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
echo "Detected IP      : $PUBLIC_IP"
echo "Tendermint RPC   : http://$PUBLIC_IP:26657"
echo "JSON-RPC (EVM)   : http://$PUBLIC_IP:8545"
echo "WS JSON-RPC      : ws://$PUBLIC_IP:8546"
echo
echo "If you ever need a hard reset:"
echo "  stabled comet unsafe-reset-all"
echo
echo "Done."
