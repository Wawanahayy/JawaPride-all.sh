#!/bin/bash
tput reset
tput civis

# Menampilkan tampilan dari display.sh
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

while true; do
    echo "1. Install Docker"
    echo "2. Install node TITAN"
    echo "3. Restart node"
    echo "4. Stop node"
    echo "5. Exit"
    echo ""
    read -p "Pilih opsi (Select option): " option

    case $option in
        1)
            # update packages
            echo "Updating packages... "
            sleep 2
            if sudo apt update -y && sudo apt-get upgrade; then
                sleep 1
                echo -e "Updating packages: Success (\e[32mSuccess\e[0m)"
                sleep 1
            else
                echo -e "Updating packages: Error (\e[31mError\e[0m)"
                exit 1
            fi

            # install additional packages
            echo "Installing additional packages..."
            sleep 2
            if sudo apt install -y ca-certificates curl gnupg lsb-release; then
                echo -e "Package installation: Success (\e[32mSuccess\e[0m)"
            else
                echo -e "Package installation: Error (\e[31mError\e[0m)"
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
                echo -e "Docker installation: Success (\e[32mSuccess\e[0m) \n \e[33mTo complete Docker setup: \n 1) exit the script \n 2) type exit \n 3) reopen terminal.\e[0m"
            else
                echo -e "Docker installation: Error (\e[31mError\e[0m)"
                exit 1
            fi
            ;;
        2)
            echo "Installing node... "
            echo ""
            sleep 2
            read -p "Enter Your Identity Code: " identity_code

            # install Docker Compose
            echo "Installing Docker Compose..."
            sleep 2
            if sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&
               sudo chmod +x /usr/local/bin/docker-compose; then
                echo -e "Docker Compose installation: Success (\e[32mSuccess\e[0m)"
            else
                echo -e "Docker Compose installation: Error (\e[31mError\e[0m)"
                exit 1
            fi

            # Download Titan image
            echo "Downloading Titan image..."
            sleep 1
            if docker pull nezha123/titan-edge && mkdir -p ~/.titanedge; then
                echo -e "Image downloaded: Success (\e[32mSuccess\e[0m)"
            else
                echo -e "Image downloaded: Error (\e[31mError\e[0m)"
                exit 1
            fi

            # Launch container
            echo "Launching container..."
            sleep 1
            if docker run --network=host -d -v ~/.titanedge:/root/.titanedge nezha123/titan-edge; then
                echo -e "Container started: Success (\e[32mSuccess\e[0m)"
            else
                echo -e "Container started: Error (\e[31mError\e[0m)"
                exit 1
            fi

            # Linking the keys
            echo "Linking the keys..."
            sleep 1
            if docker run --rm -it -v ~/.titanedge:/root/.titanedge nezha123/titan-edge bind --hash="$identity_code" https://api-test1.container1.titannet.io/api/v2/device/binding; then
                echo -e "Keys linked: Success (\e[32mSuccess\e[0m)"
            else
                echo -e "Keys linked: Error (\e[31mError\e[0m)"
                exit 1
            fi
            echo ""
            echo -e "\e[32m------ SUCCESS!!! ------\e[0m"
            echo -e "Titan node installation completed"
            echo ""
            echo -e "\n Follow my channel Beloglazov invest, \n to stay updated on the latest nodes and activities \n https://t.me/beloglazovinvest\n"
            ;;
        3)
            echo "Restarting node..."
            if docker run --name titan -d -v ~/.titanedge:/root/.titanedge nezha123/titan-edge; then
                echo -e "Restart completed: Success (\e[32mSuccess\e[0m)"
            else
                echo -e "Restart completed: Error (\e[31mError\e[0m)"
                exit 1
            fi
            ;;
        4)
            show_orange "Stopping node..."
            sleep 1
            if docker stop titan; then
                sleep 1
                echo ""
                show_orange "Success"
                echo ""
            else
                sleep 1
                echo ""
                show_orange "Fail"
                echo ""
            fi
            echo ""
            ;;
        5)
            echo -e "\e[31mScript stopped\e[0m"
            exit 0
            ;;
        *)
            echo ""
            echo -e "\e[31mInvalid option.\e[0m Please select 1, 2."
            echo ""
            ;;
    esac
done
