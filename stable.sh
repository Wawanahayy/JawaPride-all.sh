#!/usr/bin/env bash
set -euo pipefail


# ===== Basic config =====
CHAIN_ID="stabletestnet_2201-1"
BINARY_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/stabled-latest-linux-amd64-testnet.tar.gz"
GENESIS_ZIP_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/stable_testnet_genesis.zip"
CONFIG_ZIP_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/rpc_node_config.zip"
SNAPSHOT_URL="https://stable-snapshot.s3.eu-central-1.amazonaws.com/snapshot.tar.lz4"

HOME_DIR="${HOME}"
CONFIG_DIR="${HOME_DIR}/.stabled/config"
DATA_DIR="${HOME_DIR}/.stabled/data"
SERVICE_NAME="stabled"
USER_NAME="$(whoami)"

# ===== UI helpers =====
log()  { printf "\n\033[1;32m>>> %s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\n\033[1;31m[ERR]\033[0m %s\n" "$*"; }

# ===== Arg/env handling =====
YES="${YES:-n}"            # YES=y to auto-accept
AUTO_YES="n"
if [[ "${1:-}" == "-y" || "${1:-}" == "--yes" || "${YES}" =~ ^[Yy]$ ]]; then
  AUTO_YES="y"
  shift || true
fi

# Allow passing KEY=VALUE after -y
while [[ $# -gt 0 ]]; do
  case "$1" in
    *=*) eval "$1"; shift ;;
    *) warn "Unknown argument: $1"; shift ;;
  esac
done

# Defaults (can be overridden by env/args above)
MONIKER="${MONIKER:-stable-node}"
USE_SNAPSHOT="${USE_SNAPSHOT:-N}"   # y/N
OPEN_RPC="${OPEN_RPC:-N}"           # y/N
USE_UFW="${USE_UFW:-N}"             # y/N

# ===== Safety & requirements =====
trap 'err "Terjadi kesalahan pada baris $LINENO."; exit 1' ERR

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    warn "Perintah '$1' tidak ditemukan. Menginstal..."
    sudo apt update && sudo apt install -y "$1"
  }
}

assert_bash() {
  if [ -z "${BASH_VERSION:-}" ]; then
    err "Harus dijalankan dengan bash. Gunakan: bash $0"
    exit 1
  fi
}
assert_bash

# ===== Optional banner (best-effort) =====
loading_step() {
  echo "Downloading and running display script (optional)..."
  curl -fsSL https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash || \
    warn "Display script failed (optional)."
  echo
}
loading_step

# ===== Prompt (only if not auto) =====
if [[ ! "${AUTO_YES}" =~ ^[Yy]$ ]]; then
  echo "=========================================="
  echo " Stable Testnet one-click setup"
  echo " Chain ID: ${CHAIN_ID}"
  echo "=========================================="
  echo
  read -rp "Node moniker (default: ${MONIKER}): " _in || true
  [[ -n "${_in:-}" ]] && MONIKER="${_in}"

  read -rp "Use fast snapshot for quick sync? (y/N): " _in || true
  [[ -n "${_in:-}" ]] && USE_SNAPSHOT="${_in}"

  read -rp "Open public RPC ports 26657/8545/8546? (y/N): " _in || true
  [[ -n "${_in:-}" ]] && OPEN_RPC="${_in}"

  read -rp "Configure UFW firewall automatically? (y/N): " _in || true
  [[ -n "${_in:-}" ]] && USE_UFW="${_in}"

  echo
  echo "== Summary =="
  echo "Moniker         : ${MONIKER}"
  echo "Fast snapshot   : ${USE_SNAPSHOT}"
  echo "Open RPC ports  : ${OPEN_RPC}"
  echo "Auto UFW config : ${USE_UFW}"
  echo

  read -rp "Proceed with installation? (y/N): " CONFIRM || true
  CONFIRM="${CONFIRM:-N}"
  if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
else
  echo "Running in non-interactive mode (-y)."
  echo "Moniker=${MONIKER} Snapshot=${USE_SNAPSHOT} OpenRPC=${OPEN_RPC} UFW=${USE_UFW}"
fi

# ===== Step 1: OS packages =====
log "Step 1: Updating OS and installing packages..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y build-essential git wget curl jq lz4 zstd unzip htop net-tools ufw pv perl

# ===== Step 2: Binary =====
log "Step 2: Downloading and installing stabled binary..."
cd "${HOME_DIR}"
rm -f stabled-latest-linux-amd64-testnet.tar.gz || true
wget -O stabled-latest-linux-amd64-testnet.tar.gz "${BINARY_URL}"
tar -xvzf stabled-latest-linux-amd64-testnet.tar.gz
sudo mv -f stabled /usr/bin/stabled
sudo chmod +x /usr/bin/stabled

echo
echo "stabled version:"
stabled version || warn "Cannot show version (check binary name/path)."

# ===== Step 3: Init =====
log "Step 3: Initializing node..."
stabled init "${MONIKER}" --chain-id "${CHAIN_ID}"
mkdir -p "${CONFIG_DIR}"

# ===== Step 4: Genesis =====
log "Step 4: Downloading genesis..."
if [ -f "${CONFIG_DIR}/genesis.json" ]; then
  cp -f "${CONFIG_DIR}/genesis.json" "${CONFIG_DIR}/genesis.json.backup.$(date +%s)" || true
fi
cd "${HOME_DIR}"
rm -f stable_testnet_genesis.zip genesis.json || true
wget -O stable_testnet_genesis.zip "${GENESIS_ZIP_URL}"
unzip -o stable_testnet_genesis.zip
cp -f genesis.json "${CONFIG_DIR}/genesis.json"
echo
echo "Genesis checksum:"
sha256sum "${CONFIG_DIR}/genesis.json" || true

# ===== Step 5: Configs =====
log "Step 5: Applying recommended config..."
cd "${HOME_DIR}"
rm -f rpcnode_config.zip config.toml || true
wget -O rpcnode_config.zip "${CONFIG_ZIP_URL}"
unzip -o rpcnode_config.zip

if [ -f "${CONFIG_DIR}/config.toml" ]; then
  cp -f "${CONFIG_DIR}/config.toml" "${CONFIG_DIR}/config.toml.backup.$(date +%s)" || true
fi
cp -f config.toml "${CONFIG_DIR}/config.toml"

# Escape moniker safely
ESCAPED_MONIKER="$(printf '%s' "${MONIKER}" | sed 's/[&/\\]/\\&/g')"
sed -i "s/^moniker = \".*\"/moniker = \"${ESCAPED_MONIKER}\"/" "${CONFIG_DIR}/config.toml" || true

echo "Tuning P2P/RPC in config.toml..."
sed -i 's/^max_num_inbound_peers *=.*/max_num_inbound_peers = 50/' "${CONFIG_DIR}/config.toml" || true
sed -i 's/^max_num_outbound_peers *=.*/max_num_outbound_peers = 30/' "${CONFIG_DIR}/config.toml" || true
sed -i 's|^persistent_peers *=.*|persistent_peers = "5ed0f977a26ccf290e184e364fb04e268ef16430@37.187.147.27:26656,128accd3e8ee379bfdf54560c21345451c7048c7@37.187.147.22:26656"|' "${CONFIG_DIR}/config.toml" || true
sed -i 's/^pex *=.*/pex = true/' "${CONFIG_DIR}/config.toml" || true
sed -i 's|^laddr *= .*|laddr = "tcp://0.0.0.0:26657"|' "${CONFIG_DIR}/config.toml" || true
sed -i 's/^max_open_connections *=.*/max_open_connections = 900/' "${CONFIG_DIR}/config.toml" || true

# app.toml JSON-RPC
APP_TOML="${CONFIG_DIR}/app.toml"
if [ -f "${APP_TOML}" ]; then
  echo "Updating JSON-RPC section in app.toml..."
  if grep -q "^\[json-rpc\]" "${APP_TOML}"; then
    perl -0pi -e '
      s/\[json-rpc\]\s*([^[]*)/\[json-rpc\]\nenable = true\naddress = "0.0.0.0:8545"\nws-address = "0.0.0.0:8546"\nallow-unprotected-txs = true\n\n/s
    ' "${APP_TOML}" || true
  else
    cat <<'EOF' >> "${APP_TOML}"

[json-rpc]
enable = true
address = "0.0.0.0:8545"
ws-address = "0.0.0.0:8546"
allow-unprotected-txs = true
EOF
  fi
else
  warn "app.toml not found at ${APP_TOML}, please edit it manually later."
fi

# ===== Step 6: Snapshot (optional) =====
if [[ "${USE_SNAPSHOT}" =~ ^[Yy]$ ]]; then
  log "Step 6: Fast sync via snapshot..."
  mkdir -p "${HOME_DIR}/snapshot"
  cd "${HOME_DIR}/snapshot"
  mkdir -p "${DATA_DIR}"
  rm -rf "${DATA_DIR:?}/"* || true
  wget -c -O snapshot.tar.lz4 "${SNAPSHOT_URL}"
  echo "Extracting snapshot to ${HOME_DIR}/.stabled ..."
  pv snapshot.tar.lz4 | tar -I lz4 -xf - -C "${HOME_DIR}/.stabled"
else
  log "Step 6: Skipping snapshot (sync from scratch)."
fi

# ===== Step 7: Firewall (UFW, best-effort) =====
try_configure_ufw() {
  sudo ufw allow 22/tcp || true
  sudo ufw allow 26656/tcp || true
  if [[ "${OPEN_RPC}" =~ ^[Yy]$ ]]; then
    sudo ufw allow 26657/tcp || true
    sudo ufw allow 8545/tcp || true
    sudo ufw allow 8546/tcp || true
  fi
  if ! sudo ufw --force enable; then
    warn "UFW enable failed. Continuing without firewall changes."
    return 1
  fi
  return 0
}

if [[ "${USE_UFW}" =~ ^[Yy]$ ]]; then
  log "Step 7: Configuring UFW firewall (best-effort)..."
  if ! try_configure_ufw; then
    warn "Skipping UFW (provider/container may block firewall)."
  fi
else
  log "Step 7: Skipping UFW auto configuration."
  echo "Manual commands:"
  echo "  sudo ufw allow 22,26656/tcp"
  [[ "${OPEN_RPC}" =~ ^[Yy]$ ]] && echo "  sudo ufw allow 26657,8545,8546/tcp"
  echo "  sudo ufw enable"
fi

# ===== Step 8: systemd service =====
log "Step 8: Creating systemd service..."

if ! pidof systemd >/dev/null 2>&1; then
  warn "Systemd not detected/running. Service will NOT be created."
  echo "You can start manually:"
  echo "  /usr/bin/stabled start --chain-id ${CHAIN_ID}"
  exit 0
fi

sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" >/dev/null <<EOF
[Unit]
Description=Stable Daemon Service
After=network-online.target
Wants=network-online.target

[Service]
User=${USER_NAME}
ExecStart=/usr/bin/stabled start --chain-id ${CHAIN_ID}
Restart=always
RestartSec=3
LimitNOFILE=65535
StandardOutput=journal
StandardError=journal
SyslogIdentifier=stabled
Environment=DAEMON_HOME=${HOME_DIR}/.stabled

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
if ! sudo systemctl restart "${SERVICE_NAME}"; then
  err "Failed to start service. Check logs: sudo journalctl -u ${SERVICE_NAME} -b --no-pager"
  exit 1
fi

echo
log "Service status:"
sudo systemctl status "${SERVICE_NAME}" --no-pager || true

# ===== Final info =====
echo
echo "=========================================="
echo " Stable node setup finished."
echo " Moniker        : ${MONIKER}"
echo " Chain ID       : ${CHAIN_ID}"
echo " Data dir       : ${HOME_DIR}/.stabled"
echo " Service        : ${SERVICE_NAME}"
echo "=========================================="
echo
echo "Useful commands:"
echo "  sudo journalctl -u stabled -f"
echo "  curl -s localhost:26657/status | jq '.result.sync_info'"
echo "  curl -s localhost:26657/net_info | jq '.result.n_peers'"
echo
echo "Tendermint RPC:   http://<YOUR_IP>:26657"
echo "JSON-RPC (EVM):   http://<YOUR_IP>:8545"
echo "WS JSON-RPC:      ws://<YOUR_IP>:8546"
echo
echo "Hard reset if needed:"
echo "  stabled comet unsafe-reset-all"
echo
echo "Done."
