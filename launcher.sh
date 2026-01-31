#!/bin/bash
# theSmallComparator Launcher
# Handles service management and starts the application

# Configuration
SERVICE_NAME="theSmallComparator.service"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
VENV_PYTHON="$SCRIPT_DIR/venv/bin/python3"
APP_ENTRY="$SCRIPT_DIR/main.py"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== theSmallComparator Launcher ===${NC}"

# Check if running as root (needed for service management)
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo &> /dev/null; then
            echo -e "${RED}Error: sudo is required for service management but not installed.${NC}"
            return 1
        fi
        return 0
    else
        return 0 # Running as root
    fi
}

manage_service() {
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${YELLOW}The background service '$SERVICE_NAME' is currently RUNNING.${NC}"
        read -p "Do you want to STOP the service before starting a manual instance? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            echo -e "${YELLOW}Stopping service...${NC}"
            if check_sudo; then
                sudo systemctl stop "$SERVICE_NAME"
                echo -e "${GREEN}Service stopped.${NC}"
            else
                 echo -e "${RED}Cannot stop service without sudo.${NC}"
            fi
        else

            echo -e "${YELLOW}Warning: Running multiple instances might cause port conflicts.${NC}"
            read -p "Do you want to run a manual instance anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${GREEN}Exiting.${NC}"
                exit 0
            fi
        fi
    else
        echo -e "${GREEN}The background service '$SERVICE_NAME' is NOT running.${NC}"
        read -p "Do you want to START the service instead of running manually? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
             echo -e "${YELLOW}Starting service...${NC}"
             if check_sudo; then
                sudo systemctl start "$SERVICE_NAME"
                echo -e "${GREEN}Service started.${NC}"
                exit 0
             else
                 echo -e "${RED}Cannot start service without sudo.${NC}"
             fi
        fi
    fi

    # Autostart management
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        echo -e "${YELLOW}Autostart is ENABLED.${NC}"
        read -p "Do you want to DISABLE autostart? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if check_sudo; then
                sudo systemctl disable "$SERVICE_NAME"
                echo -e "${GREEN}Autostart disabled.${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}Autostart is DISABLED.${NC}"
        read -p "Do you want to ENABLE autostart? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if check_sudo; then
                sudo systemctl enable "$SERVICE_NAME"
                echo -e "${GREEN}Autostart enabled.${NC}"
            fi
        fi
    fi
}

# Only manage service if systemd is available
if command -v systemctl &> /dev/null; then
    manage_service
fi

echo -e "${GREEN}Starting theSmallComparator manually...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop.${NC}"

if [ -f "$VENV_PYTHON" ] && [ -f "$APP_ENTRY" ]; then
    "$VENV_PYTHON" "$APP_ENTRY"
else
    echo -e "${RED}Error: Virtual environment or application entry point not found.${NC}"
    echo -e "Expected python: $VENV_PYTHON"
    echo -e "Expected app: $APP_ENTRY"
    exit 1
fi
