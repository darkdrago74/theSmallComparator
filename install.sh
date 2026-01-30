#!/bin/bash

# theSmallComparator Complete Installation Script
# Simplified version with streamlined menu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== theSmallComparator Installation Suite ===${NC}"

# Function to check for SELinux availability
has_selinux() {
    command -v sestatus &> /dev/null || [ -f /etc/selinux/config ]
}

# Function to show main menu
show_main_menu() {
    echo ""
    echo -e "${YELLOW}What would you like to do?${NC}"
    echo "1) Install/Manage theSmallComparator"
    echo "2) Check Installation Status"
    echo "3) Help - Useful Commands and Information"
    echo "4) Exit"
    read -p "Enter your choice (1-4): " choice
    echo ""
}

# Function to manage theSmallComparator
manage_theSmallComparator() {
    echo -e "${YELLOW}=== theSmallComparator Management ===${NC}"
    echo "1) Install theSmallComparator"
    echo "2) Uninstall theSmallComparator"
    echo "3) Back to main menu"
    read -p "Enter your choice (1-3): " comp_choice
    echo ""
    
    case $comp_choice in
        1)
            echo -e "${YELLOW}Installing theSmallComparator...${NC}"

            # Stop and disable service to ensure a clean state
            if command -v sudo &> /dev/null; then
                sudo systemctl stop theSmallComparator.service 2>/dev/null || true
                sudo systemctl disable theSmallComparator.service 2>/dev/null || true
            fi

            # Check for SELinux and apply fix if needed
            if has_selinux && command -v ausearch &> /dev/null && command -v audit2allow &> /dev/null && command -v semodule &> /dev/null; then
                echo -e "${YELLOW}SELinux detected. Checking for policies...${NC}"
                if sudo ausearch -c '(python3)' --raw | sudo audit2allow -M my-python3; then
                    echo -e "${GREEN}SELinux policy module 'my-python3' created.${NC}"
                    if sudo semodule -X 300 -i my-python3.pp; then
                        echo -e "${GREEN}SELinux policy module 'my-python3' installed successfully.${NC}"
                    else
                        echo -e "${RED}Failed to install SELinux policy module. Please check for errors.${NC}"
                    fi
                else
                    echo -e "${YELLOW}Could not create SELinux policy module. This might be normal if no denials were logged.${NC}"
                    echo -e "${YELLOW}If you encounter issues, please consult the SELinux documentation.${NC}"
                fi
            fi

            # Run the actual theSmallComparator installation process
            # This replicates the original installation logic
            echo -e "${YELLOW}Checking prerequisites...${NC}"

            # Check if git is installed
            if ! command -v git &> /dev/null; then
                echo -e "${RED}Git is not installed. Installing...${NC}"
                if command -v sudo &> /dev/null; then
                    if command -v dnf &> /dev/null; then
                        sudo dnf install -y git
                    elif command -v apt-get &> /dev/null; then
                        sudo apt update && sudo apt install -y git
                    else
                        echo -e "${RED}Cannot install git automatically. Please install git manually.${NC}"
                        read -p "Press Enter to continue anyway..."
                        return
                    fi
                else
                    echo -e "${RED}Cannot install git without sudo. Please install git manually.${NC}"
                    read -p "Press Enter to continue anyway..."
                    return
                fi
            else
                echo -e "${GREEN}✓ Git is installed${NC}"
            fi

            # Check if Python 3 is installed
            if ! command -v python3 &> /dev/null; then
                echo -e "${RED}Python 3 is not installed. This is required for theSmallComparator.${NC}"
                if command -v sudo &> /dev/null; then
                    if command -v dnf &> /dev/null; then
                        sudo dnf install -y python3 python3-pip
                    elif command -v apt-get &> /dev/null; then
                        sudo apt update && sudo apt install -y python3 python3-pip
                    else
                        echo -e "${RED}Cannot install Python automatically. Please install Python 3 manually.${NC}"
                        read -p "Press Enter to continue anyway..."
                        return
                    fi
                else
                    echo -e "${RED}Cannot install Python without sudo. Please install Python 3 manually.${NC}"
                    read -p "Press Enter to continue anyway..."
                    return
                fi
            else
                echo -e "${GREEN}✓ Python 3 is installed${NC}"
            fi

            # Check if pip3 is available
            if ! command -v pip3 &> /dev/null; then
                echo -e "${RED}pip3 is not installed. Installing...${NC}"
                if command -v sudo & > /dev/null; then
                    if command -v dnf &> /dev/null; then
                        sudo dnf install -y python3-pip
                    elif command -v apt-get &> /dev/null; then
                        sudo apt install -y python3-pip
                    else
                        echo -e "${RED}Cannot install pip automatically.${NC}"
                        read -p "Press Enter to continue anyway..."
                        return
                    fi
                fi
            else
                echo -e "${GREEN}✓ pip3 is installed${NC}"
            fi

            # Check if v4l-utils and other system deps are available
            if ! command -v v4l2-ctl &> /dev/null; then
                echo -e "${YELLOW}Installing system dependencies (v4l-utils, libglib2.0-0)...${NC}"
                if command -v sudo &> /dev/null; then
                    if command -v dnf &> /dev/null; then
                        sudo dnf install -y v4l-utils glib2
                    elif command -v apt-get &> /dev/null; then
                         sudo apt update && sudo apt install -y v4l-utils libglib2.0-0
                    else
                         echo -e "${RED}Cannot install system dependencies automatically.${NC}"
                    fi
                fi
            else
                echo -e "${GREEN}✓ v4l-utils is installed${NC}"
            fi

            # Check for Python 3.11 specifically
            if ! command -v python3.11 &> /dev/null; then
                echo -e "${YELLOW}Python 3.11 not found. Installing...${NC}"
                if command -v sudo &> /dev/null; then
                    if command -v dnf &> /dev/null; then
                        sudo dnf install -y python3.11
                    elif command -v apt-get &> /dev/null; then
                         sudo apt update && sudo apt install -y python3.11 python3.11-venv python3.11-dev
                    else
                         echo -e "${RED}Cannot install Python 3.11 automatically.${NC}"
                         return
                    fi
                else
                    echo -e "${RED}sudo not available. Please install 'python3.11' manually.${NC}"
                    return
                fi
            else
                echo -e "${GREEN}✓ Python 3.11 is installed${NC}"
            fi

            # Create Python virtual environment and install packages
            VENV_DIR="venv"
            REQUIREMENTS_FILE="./dependencies/requirements-simple.txt"

            echo -e "${YELLOW}Checking for python3.11-venv package...${NC}"
            if command -v dpkg &> /dev/null; then
                if ! dpkg -s python3.11-venv >/dev/null 2>&1; then
                    echo -e "${YELLOW}python3.11-venv not found. Installing...${NC}"
                    if command -v sudo &> /dev/null; then
                        sudo apt-get update && sudo apt-get install -y python3.11-venv
                    else
                        echo -e "${RED}sudo not available. Please install 'python3.11-venv' manually.${NC}"
                        return
                    fi
                fi
            fi

            echo -e "${YELLOW}Creating Python virtual environment at '$VENV_DIR' using Python 3.11...${NC}"
            if ! python3.11 -m venv --clear "$VENV_DIR"; then
                echo -e "${RED}✗ Failed to create Python virtual environment.${NC}"
                return
            fi
            echo -e "${GREEN}✓ Virtual environment created successfully using Python 3.11.${NC}"




            echo -e "${YELLOW}Installing required Python packages into the virtual environment...${NC}"
            if [ -f "$REQUIREMENTS_FILE" ]; then
                # Upgrade pip, setuptools and wheel first to ensure build environment works
                echo -e "${YELLOW}Upgrading pip, setuptools, and wheel...${NC}"
                ./${VENV_DIR}/bin/pip install --upgrade --no-cache-dir pip setuptools wheel
                
                if ./${VENV_DIR}/bin/pip install --no-cache-dir -r "$REQUIREMENTS_FILE"; then
                    echo -e "${GREEN}✓ Python packages installed successfully.${NC}"
                else
                    echo -e "${RED}✗ Failed to install Python packages.${NC}"
                    return
                fi
            else
                echo -e "${RED}✗ requirements-simple.txt not found!${NC}"
                return
            fi

            echo -e "${YELLOW}Creating system-wide command...${NC}"
            chmod +x "$(pwd)/launcher.sh"
            if command -v sudo &> /dev/null; then
                sudo ln -sf "$(pwd)/launcher.sh" /usr/local/bin/theSmallComparator 2>/dev/null || \
                sudo cp "$(pwd)/launcher.sh" /usr/local/bin/theSmallComparator 2>/dev/null || \
                echo -e "${YELLOW}Could not create system-wide command. You can run theSmallComparator with './launcher.sh'${NC}"
            else
                echo -e "${YELLOW}Sudo not available, skipping system-wide command creation${NC}"
            fi

            # Set up systemd service for auto-start
            echo -e "${YELLOW}Setting up systemd service for auto-start...${NC}"
            if command -v sudo &> /dev/null; then
                PROJECT_ROOT="$(pwd)"
                SERVICE_FILE="/etc/systemd/system/theSmallComparator.service"
                
                SERVICE_CONTENT="[Unit]
Description=theSmallComparator Flask GUI
After=network.target multi-user.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$PROJECT_ROOT
Environment=PATH=/usr/bin
Environment=PYTHONPATH=$PROJECT_ROOT
ExecStart=$PROJECT_ROOT/venv/bin/python3 $PROJECT_ROOT/main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target"

                echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_FILE" 2>/dev/null
                sudo systemctl daemon-reload 2>/dev/null
                echo -e "${GREEN}theSmallComparator systemd service created${NC}"
                
                # Ask user if they want to enable auto-start
                read -p "Do you want to enable theSmallComparator to start automatically on boot? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    sudo systemctl enable theSmallComparator.service 2>/dev/null
                    sudo systemctl start theSmallComparator.service 2>/dev/null
                    echo -e "${GREEN}theSmallComparator service enabled to start on boot${NC}"
                else
                    echo -e "${YELLOW}Auto-start service created but not enabled.${NC}"
                fi
            else
                echo -e "${YELLOW}Sudo not available, skipping systemd service setup${NC}"
            fi

            # Add user to dialout group for serial access
            if command -v sudo &> /dev/null; then
                sudo usermod -a -G dialout $USER 2>/dev/null
                echo -e "${GREEN}User added to dialout group for serial port access${NC}"
            fi

            # Add user to video group for camera access
            if command -v sudo &> /dev/null; then
                sudo usermod -a -G video $USER 2>/dev/null
                echo -e "${GREEN}User added to video group for camera access${NC}"
            fi

            echo -e "${GREEN}=== theSmallComparator Installation Completed ===${NC}"
            echo -e "${GREEN}To start theSmallComparator:${NC}"
            echo -e "  - Run: ./launcher.sh${NC}"
            echo -e "  - Or access the web interface at: http://localhost:5001${NC}"
            echo -e "${YELLOW}Note: Log out and log back in for group changes to take effect${NC}"
            ;;
        2)
            echo -e "${YELLOW}Uninstalling theSmallComparator...${NC}"
            if [ -f "./dependencies/uninstall.sh" ]; then
                chmod +x ./dependencies/uninstall.sh
                ./dependencies/uninstall.sh --remove-all
            else
                echo -e "${RED}theSmallComparator uninstall script not found!${NC}"
            fi
            ;;
        3)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            ;;
    esac
    read -p "Press Enter to continue..."
}



# Function to check installation status
# Function to check installation status
check_status() {
    echo -e "${YELLOW}=== Installation Status ===${NC}"
    
    # Check theSmallComparator
    echo -e "${BLUE}theSmallComparator:${NC}"
    if [ -f "/usr/local/bin/theSmallComparator" ]; then
        echo -e "  ${GREEN}✓ System-wide command available: theSmallComparator${NC}"
    else
        echo -e "  ${RED}✗ System-wide command not installed${NC}"
    fi
    
    if [ -f "/etc/systemd/system/theSmallComparator.service" ]; then
        echo -e "  ${BLUE}Systemd Service:${NC}"
        if systemctl is-enabled theSmallComparator.service >/dev/null 2>&1; then
            echo -e "    ${GREEN}✓ Enabled for auto-start${NC}"
        else
            echo -e "    ${YELLOW}~ Not enabled for auto-start${NC}"
        fi
        
        if systemctl is-active theSmallComparator.service >/dev/null 2>&1; then
            echo -e "    ${GREEN}✓ Currently active (running)${NC}"
        else
            echo -e "    ${YELLOW}~ Not active (stopped)${NC}"
        fi
    else
        echo -e "  ${RED}✗ Service not installed${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to show help information
show_help() {
    echo -e "${YELLOW}=== Help - Useful Commands and Information ===${NC}"
    
    # Network information
    echo -e "${BLUE}Network Information:${NC}"
    IP_ADDR=$(hostname -I | awk '{print $1}')
    if [ -n "$IP_ADDR" ]; then
        echo "  IP Address: $IP_ADDR"
    else
        echo "  IP Address: Unable to determine"
    fi
    
    # Service commands
    echo -e "${BLUE}Service Management:${NC}"
    echo "  Start theSmallComparator: sudo systemctl start theSmallComparator"
    echo "  Stop theSmallComparator: sudo systemctl stop theSmallComparator"
    echo "  Restart theSmallComparator: sudo systemctl restart theSmallComparator"
    echo "  Enable theSmallComparator auto-start: sudo systemctl enable theSmallComparator"
    echo "  Disable theSmallComparator auto-start: sudo systemctl disable theSmallComparator"
    echo "  theSmallComparator status: sudo systemctl status theSmallComparator"
    
    echo ""
    
    # Web interfaces
    echo -e "${BLUE}Web Interfaces:${NC}"
    if [ -n "$IP_ADDR" ]; then
        echo "  theSmallComparator: http://$IP_ADDR:5001"
    else
        echo "  theSmallComparator: http://[YOUR_IP]:5001"
    fi
    
    # System commands
    echo -e "${BLUE}System Commands:${NC}"
    echo "  Reboot Raspberry Pi: sudo reboot"
    echo "  Shutdown Raspberry Pi: sudo shutdown now"
    echo "  Check disk space: df -h"
    echo "  Check memory usage: free -h"
    echo "  Check running processes: top"
    
    # Troubleshooting
    echo -e "${BLUE}Troubleshooting:${NC}"
    echo "  Check theSmallComparator logs: sudo journalctl -u theSmallComparator -f"
    echo "  Check system logs: sudo journalctl -xe"
    
    read -p "Press Enter to continue..."
}

# Main loop
while true; do
    show_main_menu
    case $choice in
        1)
            manage_theSmallComparator
            ;;
        2)
            check_status
            ;;
        3)
            show_help
            ;;
        4)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice! Please try again.${NC}"
            ;;
    esac
done
