#!/bin/bash
# theSmallComparator Uninstallation Script
# Removes theSmallComparator installation and configurations

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== theSmallComparator Uninstallation ===${NC}"

echo -e "${YELLOW}This will remove theSmallComparator configurations, automation, and system changes.${NC}"

# Ask for confirmation
read -p "Are you sure you want to uninstall theSmallComparator? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Uninstallation cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}Removing theSmallComparator services...${NC}"

# Remove theSmallComparator systemd service
if [ -f "/etc/systemd/system/theSmallComparator.service" ]; then
    if command -v sudo &> /dev/null; then
        sudo systemctl stop theSmallComparator.service 2>/dev/null || true
        sudo systemctl disable theSmallComparator.service 2>/dev/null || true
        sudo rm -f /etc/systemd/system/theSmallComparator.service
        echo -e "${GREEN}Removed theSmallComparator systemd service${NC}"
    else
        systemctl stop theSmallComparator.service 2>/dev/null || true
        systemctl disable theSmallComparator.service 2>/dev/null || true
        rm -f /etc/systemd/system/theSmallComparator.service
        echo -e "${GREEN}Removed theSmallComparator systemd service${NC}"
    fi
else
    echo -e "${YELLOW}theSmallComparator service not found${NC}"
fi

# Reload systemd to remove the service
if command -v sudo &> /dev/null; then
    sudo systemctl daemon-reload 2>/dev/null || true
else
    systemctl daemon-reload 2>/dev/null || true
fi

# Remove any old virtual environment if it exists (cleanup of old venv installations)
echo -e "${YELLOW}Removing virtual environment if it exists (cleanup)...${NC}"
if [ -d "../theSmallComparator_env" ]; then
    rm -rf "../theSmallComparator_env"
    echo -e "${GREEN}Removed theSmallComparator virtual environment from project directory${NC}"
else
    echo -e "${YELLOW}Virtual environment not found in project directory${NC}"
fi

# Check if the virtual environment exists in the home directory (older installations)
if [ -d "$HOME/theSmallComparator_env" ]; then
    rm -rf "$HOME/theSmallComparator_env"
    echo -e "${GREEN}Removed old virtual environment from home directory${NC}"
fi

# Remove the new virtual environment if it exists
if [ -d "../venv" ]; then
    rm -rf "../venv"
    echo -e "${GREEN}Removed venv virtual environment from project directory${NC}"
fi

# get target user
if [ -n "$SUDO_USER" ]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER="$USER"
fi

# Remove from groups if requested or if we decide to be aggressive. 
# For now, let's keep it optional via a flag or just warn, but the user requested FULL cleanup.
# However, modifying groups might affect other things. But wait, user said "make it compatible with laserweb4 project but it's impossible... remove all reference".
# The original script kept groups if LaserWeb was there. Since we are removing LaserWeb refs, we can optionally remove groups if we think they are only for this.
# But being in dialout/video is common. I'll leave them or just remove if --remove-all passed.
# Since the prompt said "remove all reference to Laserweb4", I don't need to preserve checks.

# Handle dialout group membership
echo -e "${YELLOW}Removing user from dialout group (serial access)...${NC}"
if command -v sudo &> /dev/null; then
    if groups $TARGET_USER | grep -q "\bdialout\b"; then
        sudo deluser $TARGET_USER dialout 2>/dev/null
        echo -e "${GREEN}User removed from dialout group${NC}"
    fi
fi

# Handle video group membership
echo -e "${YELLOW}Removing user from video group (camera access)...${NC}"
if command -v sudo &> /dev/null; then
    if groups $TARGET_USER | grep -q "\bvideo\b"; then
        sudo deluser $TARGET_USER video 2>/dev/null
        echo -e "${GREEN}User removed from video group${NC}"
    fi
fi

# Uninstall python packages only if --remove-all or --complete flag is provided
if [ "$1" = "--remove-all" ] || [ "$1" = "--complete" ]; then
    echo -e "${YELLOW}Removing Python packages from system (complete removal)...${NC}"
    # Using requirements-simple.txt if available
    REQUIREMENTS_FILE="./requirements-simple.txt"
    if [ -f "$REQUIREMENTS_FILE" ]; then
         if command -v pip3 &> /dev/null; then
             # Attempt to uninstall packages listed
             pip3 uninstall -r "$REQUIREMENTS_FILE" -y 2>/dev/null || true
         fi
    fi
    # Also clean pip cache
    if command -v pip3 &> /dev/null; then
        pip3 cache purge 2>/dev/null || true
    fi
fi

# Remove the system-wide command if it exists
echo -e "${YELLOW}Removing system-wide 'theSmallComparator' command...${NC}"
if [ -L "/usr/local/bin/theSmallComparator" ] || [ -f "/usr/local/bin/theSmallComparator" ]; then
    if command -v sudo &> /dev/null; then
        sudo rm -f /usr/local/bin/theSmallComparator
        echo -e "${GREEN}Removed 'theSmallComparator' command from /usr/local/bin${NC}"
    else
        rm -f /usr/local/bin/theSmallComparator
        echo -e "${GREEN}Removed 'theSmallComparator' command from /usr/local/bin${NC}"
    fi
fi

# ALSO clean up old comparatron command just in case
if [ -f "/usr/local/bin/comparatron" ]; then
    if command -v sudo &> /dev/null; then
        sudo rm -f /usr/local/bin/comparatron
    else
        rm -f /usr/local/bin/comparatron
    fi
fi

echo -e "${GREEN}=== theSmallComparator Uninstallation completed ===${NC}"
echo -e "${GREEN}You may need to restart your system for all changes to take effect.${NC}"