# theSmallComparator - Digital Optical Comparator

Enhanced digital optical comparator software with dual-mode CNC control for **GRBL** and **Klipper** based systems.
Designed for robustness on **Raspberry Pi**, Fedora, and Debian systems. The project is actively developed and tested on **Raspberry Pi Bookworm**, and is forward-compatible with the upcoming **Trixie** release.

## Overview

**theSmallComparator** is an advanced optical comparator that combines:
-   **High-Resolution Vision**: Smart camera management with instant caching and fast detection.
-   **Dual-Mode CNC Control**:
    -   **GRBL**: Classic serial communication for Arduino/Shield setups.
    -   **Klipper**: Modern HTTP API integration via Moonraker (e.g., SKR Pico, RPi).
-   **Web Interface**: Responsive UI accessible from any device on the network (`http://<ip>:5001`).
-   **CAD Integration**: DXF export of measured points.

## Quick Start

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/darkdrago74/theSmallComparator.git
    cd theSmallComparator
    ```

2.  **Run the unified installer:**
    ```bash
    chmod +x install.sh
    ./install.sh
    ```
    This script is the **single point of entry** for installation. It will automatically:
    -   Detect your OS (Debian/Raspbian/Fedora).
    -   Install critical system dependencies (`v4l-utils`, `libglib2.0-0`, etc.).
    -   Install Python dependencies from `dependencies/requirements-simple.txt` (handling PEP 668 managed environments correctly).
    -   Configure user permissions (`dialout`, `video` groups).
    -   Create a systemd service for auto-start.

    > **Note on Output**: You may see some **red error messages** during the process (e.g., `ERROR: pip's dependency resolver...`). These are related to harmless package conflicts with system libraries and are **safely ignored**. The system recovers automatically.

3.  **Log out and Log back in**: Required for group permissions (USB/Camera access) to take effect.
    ```bash
    logout
    ```

### Usage

**Start Manually:**
Run the command from any terminal:
```bash
theSmallComparator
```

**Auto-Start Service:**
If enabled during install, the service checks availability on boot.
-   **Status:** `sudo systemctl status theSmallComparator`
-   **Restart:** `sudo systemctl restart theSmallComparator`
-   **Logs:** `sudo journalctl -u theSmallComparator -f`

**Access Interface:**
Open your browser to: `http://localhost:5001` (or your device's IP, e.g., `http://raspberrypi.local:5001`).

## Connection & Camera Management

### Smart Camera Scanning
The system uses an intelligent caching mechanism to ensure instant startup.
-   **On Boot**: A background scan initializes the camera list.
-   **UI Controls**:
    -   **"Scan New (Fast)"**: (Default) Quickly checks for *newly connected* USB devices (~1-2s). Use this when plugging in a camera after boot.
    -   **"Full Rescan (Slow)"**: Performs a deep probe of all video devices (~20s). Use this only if a camera is connected but not recognized by the fast scan.

### Serial / Motion Control
-   **Klipper**: Auto-detected at `localhost:7125`.
-   **GRBL**: Auto-detected on USB serial ports.
    -   **Calibration**: GRBL settings (`$$`) are viewable and editable directly in the "Calibration" page.
    -   **Note**: You must be connected to the machine for settings to appear.

## Diagnostics

If you encounter issues (e.g., "No active serial connection" or camera failures), use the included diagnostic tools.

1.  **Hardware Probe**:
    Run this script to list all detected video devices and serial ports, and verify their accessibility without starting the full server.
    ```bash
    python3 diagnostics/hardware_probe.py
    ```

2.  **Check Logs**:
    Real-time logs are essential for troubleshooting.
    ```bash
    # Real-time service logs
    sudo journalctl -u theSmallComparator -f
    
    # Application server logs (if running manually)
    tail -f server_*.log
    ```

## Project Structure

```
theSmallComparator/
├── main.py                 # Application entry point
├── gui_flask.py            # Web Server, API, & App State
├── camera_manager.py       # Smart Camera Detection & Caching
├── serial_comm.py          # GRBL Serial Interface
├── install.sh              # Universal Installer (RPi/Fedora/Debian)
├── dependencies/
│   └── requirements-simple.txt  # Python Dependency pinning
└── diagnostics/
    └── hardware_probe.py   # Standalone hardware tester
```

## Uninstallation
To remove the application and clean up all files and services:
```bash
./dependencies/uninstall.sh --remove-all
```

## License
See the LICENSE file for licensing information.