#!/bin/bash
# Function to display messages
show() {
    echo "$1"
}

# Function to display colorful text with a delay
display_colored_text() {
    local text=(
        "============================================================"
        "=======================  J.W.P.A  =========================="
        "================= @AirdropJP_JawaPride ====================="
        "=============== https://x.com/JAWAPRIDE_ID ================="
        "============= https://linktr.ee/Jawa_Pride_ID =============="
        "============================================================"
    )

    local colors=(
        "\e[31m"  # Red
        "\e[32m"  # Green
        "\e[33m"  # Yellow
        "\e[34m"  # Blue
        "\e[35m"  # Magenta
        "\e[36m"  # Cyan
        "\e[37m"  # White
    )

    for ((i=0; i<30; i++)); do  # Loop for 30 iterations (6 seconds total with 0.2 second delay)
        for color in "${colors[@]}"; do
            clear  # Clear the terminal
            for line in "${text[@]}"; do
                echo -e "${color}${line}\e[0m"  # Display text in color
            done
            sleep 0.2  # Wait for 0.2 seconds
        done
    done
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    show "jq not found, installing..."
    sudo apt-get update
    sudo apt-get install -y jq > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        show "Failed to install jq. Please check your package manager."
        exit 1
    fi
fi

# Function to get the latest version
check_latest_version() {
    local REPO_URL="https://api.github.com/repos/block-mesh/block-mesh-monorepo/releases/latest"
    for i in {1..3}; do
        LATEST_VERSION=$(curl -s "$REPO_URL" | jq -r '.tag_name')
        if [ $? -ne 0 ]; then
            show "curl failed. Please ensure curl is installed and working properly."
            exit 1
        fi
        if [ -n "$LATEST_VERSION" ]; then
            show "Latest version available: $LATEST_VERSION"
            return 0
        fi
        show "Attempt $i: Failed to fetch the latest version. Retrying..."
        sleep 2
    done
    show "Failed to fetch the latest version after 3 attempts. Please check your internet connection or GitHub API limits."
    exit 1
}

# Call the function to get the latest version
check_latest_version

# Display the colorful text
display_colored_text

# Detect the architecture before downloading binaries
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    DOWNLOAD_URL="https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.321/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz"
elif [ "$ARCH" = "arm64" ]; then
    show "Unsupported architecture: $ARCH"
    exit 1
else
    show "Unsupported architecture: $ARCH"
    exit 1
fi

# Create 'blockmesh' directory if it doesn't exist
BLOCKMESH_DIR="$HOME/blockmesh"
if [ ! -d "$BLOCKMESH_DIR" ]; then
    show "Creating directory: $BLOCKMESH_DIR"
    mkdir -p "$BLOCKMESH_DIR"
    if [ $? -ne 0 ]; then
        show "Failed to create directory $BLOCKMESH_DIR."
        exit 1
    fi
fi

# Check if the current version matches the latest version
CURRENT_VERSION=$(grep -oP '(?<=blockmesh_)[^/]*' "$BLOCKMESH_DIR/blockmesh-cli-x86_64-unknown-linux-gnu" 2>/dev/null)
if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    # If not up to date, download the latest version
    show "Downloading blockmesh-cli..."
    curl -L "$DOWNLOAD_URL" -o "$BLOCKMESH_DIR/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz"
    if [ $? -ne 0 ]; then
        show "Failed to download file. Please check your internet connection."
        exit 1
    fi
    show "Downloaded: $BLOCKMESH_DIR/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz"
    # Extract the downloaded file into the 'blockmesh' folder
    show "Extracting file..."
    tar -xvzf "$BLOCKMESH_DIR/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz" -C "$BLOCKMESH_DIR" && rm "$BLOCKMESH_DIR/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz"
    if [ $? -ne 0 ]; then
        show "Failed to extract file."
        exit 1
    fi
    show "Extraction complete."
else
    show "You are already using the latest version: $LATEST_VERSION."
fi

# Set the service name
SERVICE_NAME="blockmesh"

# Reload systemd daemon before checking anything
sudo systemctl daemon-reload

# Check if the service exists
if systemctl status "$SERVICE_NAME" > /dev/null 2>&1; then
    # If the service exists, check if it's running
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        sudo systemctl stop "$SERVICE_NAME"
        sleep 5
    fi
    # Get existing email and password if available
    EMAIL=$(systemctl show "$SERVICE_NAME" -p Environment | grep -oP '(?<=EMAIL=).*')
    PASSWORD=$(systemctl show "$SERVICE_NAME" -p Environment | grep -oP '(?<=PASSWORD=).*')
    # Ask if the user wants to update the email or password
    read -p "Do you want to change your email? (yes/no): " change_email
    if [ "$change_email" == "yes" ]; then
        read -p "Enter your new email: " EMAIL
    fi
    read -s -p "Do you want to change your password? (yes/no): " change_password
    echo
    if [ "$change_password" == "yes" ]; then
        read -s -p "Enter your new password: " PASSWORD
        echo
    fi
else
    # If the service does not exist, inform the user about account creation
    show "Service $SERVICE_NAME does not exist. Before proceeding, please ensure you have created an account at: https://app.blockmesh.xyz/register?invite_code=2ad3bf83-bf2c-477a-8440-b98784cc71d7"
    read -p "Have you created an account? (yes/no): " account_created
    if [ "$account_created" != "yes" ]; then
        show "Please create an account before proceeding."
        exit 1
    fi
    # Get the user's email and password
    read -p "Enter your email: " EMAIL
    read -s -p "Enter your password: " PASSWORD
    echo
fi

# Create or update the systemd service file
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
cat <<EOL | sudo tee "$SERVICE_FILE"
[Unit]
Description=Blockmesh Service
After=network.target
[Service]
Type=simple
WorkingDirectory=$BLOCKMESH_DIR/target/x86_64-unknown-linux-gnu/release
ExecStart=$BLOCKMESH_DIR/target/x86_64-unknown-linux-gnu/release/blockmesh-cli login --email '$EMAIL' --password '$PASSWORD'
Restart=always
Environment=EMAIL=${EMAIL}
Environment=PASSWORD=${PASSWORD}
[Install]
WantedBy=multi-user.target
EOL
show "Service file created/updated at $SERVICE_FILE"

# Reload the systemd daemon to recognize the new service file
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"
show "Blockmesh service started."

# Display real-time logs
show "Displaying real-time logs. Press Ctrl+C to stop."
journalctl -u "$SERVICE_NAME" -f

# Exit the script after displaying logs
exit 0
