#!/bin/bash

# Color and icon definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

print_colored() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

display_colored_text() {
    print_colored "40;96" "============================================================"  
    print_colored "42;37" "=======================  J.W.P.A  ==========================" 
    print_colored "45;97" "================= @AirdropJP_JawaPride =====================" 
    print_colored "43;30" "=============== https://x.com/JAWAPRIDE_ID =================" 
    print_colored "41;97" "============= https://linktr.ee/Jawa_Pride_ID ==============" 
    print_colored "44;30" "============================================================" 
}

# Display main menu
show_menu() {
    clear
    display_colored_text
    echo -e "    ${MAGENTA}Please choose an option:${RESET}"
    echo -e "    ${MAGENTA}1.${RESET} Install Node"
    echo -e "    ${MAGENTA}2.${RESET} View Logs"
    echo -e "    ${MAGENTA}3.${RESET} Restart Node"
    echo -e "    ${MAGENTA}4.${RESET} Stop Node"
    echo -e "    ${MAGENTA}5.${RESET} Start Node"
    echo -e "    ${MAGENTA}6.${RESET} View Account"
    echo -e "    ${MAGENTA}7.${RESET} Change Account"
    echo -e "    ${MAGENTA}0.${RESET} Exit"
    echo -ne "${MAGENTA}Enter a command number [0-7]:${RESET} "
    read choice
}

install_node() {
    echo -e "${YELLOW}To continue, please register at the following link:${RESET}"
    echo -ne "${YELLOW}Have you completed registration? (y/n): ${RESET}"
    read registered

    if [[ "$registered" != "y" && "$registered" != "Y" ]]; then
        echo -e "${RED}Please complete the registration and use referral code DK to continue.${RESET}"
        read -p "Press Enter to return to the menu..."
        return
    fi

    echo -e "${GREEN}🛠️  Installing node...${RESET}"
    sudo apt update || { echo -e "${RED}Failed to update packages.${RESET}"; return; }
    
    if ! command -v docker &> /dev/null; then
        if ! sudo apt install docker.io -y; then
            echo -e "${RED}Failed to install Docker.${RESET}"
            return
        fi
        sudo systemctl start docker || { echo -e "${RED}Failed to start Docker.${RESET}"; return; }
        sudo systemctl enable docker
    fi

    if ! command -v docker-compose &> /dev/null; then
        if ! sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
            echo -e "${RED}Failed to download Docker Compose.${RESET}"
            return
        fi
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    echo -ne "${YELLOW}Enter your email:${RESET} "
    read USER_EMAIL
    while ! [[ "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
        echo -ne "${RED}Invalid email format. Please enter a valid email:${RESET} "
        read USER_EMAIL
    done

    echo -ne "${YELLOW}Enter your password:${RESET} "
    read USER_PASSWORD
    while [[ -z "$USER_PASSWORD" ]]; do
        echo -ne "${RED}Password cannot be empty. Please enter a password:${RESET} "
        read USER_PASSWORD
    done

    echo "USER_EMAIL=${USER_EMAIL}" > .env
    echo "USER_PASSWORD=${USER_PASSWORD}" >> .env
    chmod 600 .env
    docker-compose up -d || { echo -e "${RED}Failed to start Docker Compose.${RESET}"; return; }
    echo -e "${GREEN}✅ Node installed successfully. Check the logs to confirm authentication.${RESET}"
    read -p "Press Enter to return to the menu..."
}

# View logs function
view_logs() {
    echo -e "${GREEN}📄 Viewing logs...${RESET}"
    docker-compose logs
    echo
    read -p "Press Enter to return to the menu..."
}

# Restart node function
restart_node() {
    echo -e "${GREEN}🔄 Restarting node...${RESET}"
    docker-compose down
    docker-compose up -d || { echo -e "${RED}Failed to restart the node.${RESET}"; return; }
    echo -e "${GREEN}✅ Node restarted.${RESET}"
    read -p "Press Enter to return to the menu..."
}

# Stop node function
stop_node() {
    echo -e "${GREEN}⏹️ Stopping node...${RESET}"
    docker-compose down || { echo -e "${RED}Failed to stop the node.${RESET}"; return; }
    echo -e "${GREEN}✅ Node stopped.${RESET}"
    read -p "Press Enter to return to the menu..."
}

# Start node function
start_node() {
    echo -e "${GREEN}▶️ Starting node...${RESET}"
    docker-compose up -d || { echo -e "${RED}Failed to start the node.${RESET}"; return; }
    echo -e "${GREEN}✅ Node started.${RESET}"
    read -p "Press Enter to return to the menu..."
}

# Change account function
change_account() {
    echo -e "${YELLOW}🔑 Changing account details...${RESET}"
    echo -ne "${YELLOW}Enter new email:${RESET} "
    read USER_EMAIL
    while ! [[ "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
        echo -ne "${RED}Invalid email format. Please enter a valid email:${RESET} "
        read USER_EMAIL
    done

    echo -ne "${YELLOW}Enter new password:${RESET} "
    read USER_PASSWORD
    while [[ -z "$USER_PASSWORD" ]]; do
        echo -ne "${RED}Password cannot be empty. Please enter a password:${RESET} "
        read USER_PASSWORD
    done

    echo "USER_EMAIL=${USER_EMAIL}" > .env
    echo "USER_PASSWORD=${USER_PASSWORD}" >> .env
    chmod 600 .env
    echo -e "${GREEN}✅ Account details updated successfully.${RESET}"
    read -p "Press Enter to return to the menu..."
}

cat_account() {
    cat .env
    read -p "Press Enter to return to the menu..."
}

# Main menu loop
while true; do
    show_menu
    case $choice in
        1)
            install_node
            ;;
        2)
            view_logs
            ;;
        3)
            restart_node
            ;;
        4)
            stop_node
            ;;
        5)
            start_node
            ;;
        6)
            cat_account
            ;;
        7)
            change_account
            ;;
        0)
            echo -e "${GREEN}❌ Exiting...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid input. Please try again.${RESET}"
            read -p "Press Enter to continue..."
            ;;
    esac
done
