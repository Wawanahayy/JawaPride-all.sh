#!/bin/bash
tput reset
tput civis

# Alias untuk warna
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# Menampilkan tampilan dari display.sh
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

while true; do
    echo "1. Install Docker"
    echo "2. Install node TITAN"
    echo "3. Restart node"
    echo "4. Stop node"
    echo "5. View node logs"
    echo "6. Exit"
    echo ""
    read -p "Pilih opsi (Select option): " option

    case $option in
        1)
            # Update packages
            echo "Updating packages... "
            sleep 2
            if sudo apt update -y && sudo apt-get upgrade; then
                sleep 1
                echo -e "Updating packages: Success (${GREEN}Success${RESET})"
                sleep 1
            else
                echo -e "Updating packages: Error (${RED}Error${RESET})"
                exit 1
            fi

            # Install additional packages
            echo "Installing additional packages..."
            sleep 2
            if sudo apt install -y ca-certificates curl gnupg lsb-release; then
                echo -e "Package installation: Success (${GREEN}Success${RESET})"
            else
                echo -e "Package installation: Error (${RED}Error${RESET})"
                exit 1
            fi

            # Docker installation
            echo "Installing Docker..."
            sleep 2
            if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&
               echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
               sudo apt update &&
               sudo apt install -y docker-ce docker-ce-cli containerd.io &&
               sudo usermod -aG docker $USER; then
                echo -e "Docker installation: Success (${GREEN}Success${RESET})"
            else
                echo -e "Docker installation: Error (${RED}Error${RESET})"
                exit 1
            fi
            ;;
        2)
            # Install node TITAN
            echo "Installing node TITAN..."
            sleep 2
            read -p "Enter Your Identity Code: " identity_code

            # Install Docker Compose
            echo "Installing Docker Compose..."
            sleep 2
            if sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&
               sudo chmod +x /usr/local/bin/docker-compose; then
                echo -e "${GREEN}Docker Compose installation: Success${RESET}"
            else
                echo -e "${RED}Docker Compose installation: Error${RESET}"
                exit 1
            fi

            # Download Titan image
            echo "Downloading Titan image..."
            if docker pull nezha123/titan-edge && mkdir -p ~/.titanedge; then
                echo -e "${GREEN}Image downloaded: Success${RESET}"
            else
                echo -e "${RED}Image downloaded: Error${RESET}"
                exit 1
            fi

            # Launch container
            echo "Launching container..."
            if docker run --network=host -d -v ~/.titanedge:/root/.titanedge nezha123/titan-edge; then
                echo -e "${GREEN}Container started: Success${RESET}"
            else
                echo -e "${RED}Container started: Error${RESET}"
                exit 1
            fi

            # Linking the keys
            echo "Linking the keys..."
            if docker run --rm -it -v ~/.titanedge:/root/.titanedge nezha123/titan-edge bind --hash="$identity_code" https://api-test1.container1.titannet.io/api/v2/device/binding; then
                echo -e "${GREEN}Keys linked: Success${RESET}"
            else
                echo -e "${RED}Keys linked: Error${RESET}"
                exit 1
            fi

            # Show logs and return to main menu
            echo -e "${YELLOW}Showing node logs...${RESET}"
            docker logs titan

            echo -e "${GREEN}------ SUCCESS!!! ------${RESET}"
            echo -e "${GREEN}Titan node installation completed${RESET}"
            echo -e "${GREEN}Now returning to the main menu...${RESET}"
            sleep 3
            ;;
        3)
            # Restart node
            echo "Restarting node..."
            if docker ps -q -f name=titan; then
                docker restart titan
                echo -e "${GREEN}Node restarted successfully!${RESET}"
            else
                echo -e "${RED}Node is not running!${RESET}"
            fi
            echo ""
            ;;
        4)
            # Stop node
            echo -e "${YELLOW}Stopping node...${RESET}"
            sleep 1
            if docker ps -q -f name=titan; then
                docker stop titan
                echo -e "${GREEN}Node stopped successfully!${RESET}"
            else
                echo -e "${RED}Node is not running!${RESET}"
            fi
            echo ""
            ;;
        5)
            # View logs
            echo -e "${YELLOW}Viewing node logs...${RESET}"
            sleep 1
            if docker ps -q -f name=titan; then
                docker logs titan
            else
                echo -e "${RED}Node is not running!${RESET}"
            fi
            echo ""
            ;;
        6)
            # Exit
            echo -e "${RED}Exiting script...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${RESET}"
            ;;
    esac
done
