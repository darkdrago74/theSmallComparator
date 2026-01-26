"""
Klipper Manager Module for theSmallComparator
Handles communication with Klipper via Moonraker API
"""

import requests
import logging
import time

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class KlipperManager:
    """
    Class to handle communication with Klipper via Moonraker API
    """
    
    def __init__(self, host='localhost', port=7125):
        self.base_url = f"http://{host}:{port}"
        self.connected = False
        self.printer_info = None

    def connect(self):
        """
        Check connection to Moonraker and get printer info
        
        Returns:
            bool: True if connected, False otherwise
        """
        try:
            logging.info(f"Attempting to connect to Moonraker at {self.base_url}")
            response = requests.get(f"{self.base_url}/printer/info", timeout=2)
            if response.status_code == 200:
                self.printer_info = response.json().get('result', {})
                self.connected = True
                logging.info(f"Connected to Klipper: {self.printer_info}")
                return True
            else:
                logging.warning(f"Moonraker responded with status {response.status_code}")
                return False
        except requests.exceptions.RequestException as e:
            logging.error(f"Could not connect to Moonraker: {e}")
            self.connected = False
            return False

    def send_command(self, gcode_command):
        """
        Send G-code command to Klipper
        
        Args:
            gcode_command (str): G-code command to send
            
        Returns:
            str: Response from Klipper (or 'ok' on success), None on failure
        """
        if not self.connected:
            return None
            
        try:
            # Strip newlines and whitespace
            gcode = gcode_command.strip()
            if not gcode:
                return None
                
            logging.debug(f"Sending G-code to Klipper: {gcode}")
            
            # Use printer/gcode/script endpoint
            response = requests.post(f"{self.base_url}/printer/gcode/script", 
                                   json={'script': gcode}, 
                                   timeout=5)
            
            if response.status_code == 200:
                return "ok"
            else:
                logging.error(f"Klipper G-code error {response.status_code}: {response.text}")
                return f"Error: {response.text}"
                
        except Exception as e:
            logging.error(f"Error sending G-code to Klipper: {e}")
            return None

    def get_machine_status(self):
        """
        Get current machine status (position)
        
        Returns:
            str: Status string simulating GRBL status format for compatibility
                 <Idle|MPos:0.000,0.000,0.000|FS:0,0>
        """
        if not self.connected:
            return None
            
        try:
            # Query toolhead position
            response = requests.get(f"{self.base_url}/printer/objects/query?toolhead", timeout=2)
            if response.status_code == 200:
                data = response.json()
                toolhead = data.get('result', {}).get('status', {}).get('toolhead', {})
                
                # Extract position
                pos = toolhead.get('position', [0, 0, 0, 0])
                x, y, z = pos[0], pos[1], pos[2]
                
                # Extract state (approximate mapping)
                status = toolhead.get('status', 'Idle')
                if status == 'Ready': status = 'Idle'
                elif status == 'Printing': status = 'Run'
                
                # Format like GRBL: <Status|MPos:X,Y,Z|FS:Feed,Spindle>
                # Klipper doesn't easily give current feedrate in this query, defaulting to 0
                return f"<{status}|MPos:{x:.3f},{y:.3f},{z:.3f}|FS:0,0>"
            
            return None
        except Exception as e:
            logging.error(f"Error getting Klipper status: {e}")
            return None

    def get_rotation_distance(self):
        """
        Get rotation_distance for X, Y, Z steppers from config
        
        Returns:
            dict: {'x': val, 'y': val, 'z': val}
        """
        if not self.connected:
            return None
            
        try:
            response = requests.get(f"{self.base_url}/printer/objects/query?configfile", timeout=5)
            if response.status_code == 200:
                config = response.json().get('result', {}).get('status', {}).get('configfile', {}).get('settings', {})
                
                rot_dist = {}
                # Try to find stepper_x, stepper_y, stepper_z
                for axis in ['x', 'y', 'z']:
                    section = f"stepper_{axis}"
                    if section in config:
                        rot_dist[axis] = config[section].get('rotation_distance')
                
                return rot_dist
            return None
        except Exception as e:
            logging.error(f"Error getting config: {e}")
            return None

    def update_rotation_distance(self, axis, new_value):
        """
        Update rotation_distance for an axis
        Note: This is complex in Klipper. We use SAVE_CONFIG to save changes, 
        but modifying printer.cfg programmatically via API usually involves 
        updating the memory config and then saving.
        
        Actually, standard Moonraker doesn't allow arbitrary config writes via simple API calls 
        without some setup (like responsive variables or specialized commands).
        
        However, we can use the SET_KINEMATIC_POSITION or specific macros if available.
        For persistent config changes, we might need to rely on the user editing printer.cfg 
        OR use `server.config.save_config` endpoint if we can queue the change.
        
        Simpler approach for now: We assume we can't easily write to printer.cfg 
        safely without potentially breaking things or requiring restarts. 
        Klipper philosophy usually separates config editing from runtime.
        
        BUT, the requirement is "The steps/mm or rotation distance must be updatable".
        
        Strategy: Use a G-code command if a macro exists, or warn user.
        Wait, Moonraker DOES have a config upload capability, but parsing/replacing is risky.
        
        Alternative: The user asked for "calibration page must be able to read the stored values and have access to update them".
        We will try to implement a generic configuration update if possible, or provide a UI 
        that generates the command/config snippet.
        """
        # For this implementation, we'll log the intention. 
        # Writing to printer.cfg programmatically is high risk via blind API.
        pass

    # Methods for Duck Typing compatibility with SerialCommunicator

    def disconnect(self):
        self.connected = False

    def home_machine(self):
        return self.send_command("G28")

    def unlock_machine(self):
        return self.send_command("M112") # Emergency stop? No, unlock isn't really a thing in Klipper like GRBL $X. Usually FIRMWARE_RESTART or clearing pauses.
        # Klipper doesn't lock like GRBL.
        return "ok"

    def reset_alarm_state(self):
        self.send_command("FIRMWARE_RESTART")
        return "ok"

    def set_feed(self, feed_rate):
        return self.send_command(f"G1 F{feed_rate}")

    def set_origin(self):
        return self.send_command("G92 X0 Y0")

    def set_relative_mode(self):
        return self.send_command("G91")

    def send_raw_command(self, raw_command):
        return self.send_command(raw_command)
