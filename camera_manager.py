"""
Camera Management Module for Comparatron
Handles camera selection, initialization, and video capture
"""

import cv2 as cv
import numpy as np
import logging
import os

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


"""
Camera Management Module for Comparatron
Handles camera selection, initialization, and video capture
"""

import cv2 as cv
import numpy as np
import logging
import os
import glob
import subprocess
import re
import time

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class CameraManager:
    def __init__(self):
        self._cached_cameras = []
        self._last_scan_time = 0
        self._all_video_devices = [] # Track all /dev/videoN seen to know what is "new"

    def initialize_cache(self):
        """Run an initial full scan to populate cache"""
        logging.info("Initializing camera cache...")
        self.force_full_scan()

    def get_cached_cameras(self):
        """Return the currently cached list of working cameras"""
        return self._cached_cameras

    def get_all_video_devices(self):
        """Get list of currently present /dev/video* devices"""
        devices = []
        # Check /dev/video*
        for path in glob.glob("/dev/video*"):
            try:
                idx = int(re.search(r'video(\d+)', path).group(1))
                devices.append(idx)
            except:
                pass
        return sorted(list(set(devices)))

    def scan_new_cameras(self):
        """
        Smart scan: Only probe devices that are NEW since the last scan.
        Returns the updated list of working cameras.
        """
        logging.info("Scanning for NEW cameras only...")
        current_devices = self.get_all_video_devices()
        new_candidates = [d for d in current_devices if d not in self._all_video_devices]
        
        if not new_candidates:
            logging.info("No new video devices detected.")
            return self._cached_cameras

        logging.info(f"New video devices detected: {new_candidates}")
        
        # Probe only the new candidates
        working_new_cameras = self._probe_candidates(new_candidates)
        
        # Update state
        if working_new_cameras:
            # Add to cache, avoiding duplicates and keeping sorted
            updated_cache = sorted(list(set(self._cached_cameras + working_new_cameras)))
            self._cached_cameras = updated_cache
            logging.info(f"Added {len(working_new_cameras)} new working cameras. Total: {len(self._cached_cameras)}")
        
        # Update known devices list
        self._all_video_devices = sorted(list(set(self._all_video_devices + current_devices)))
        
        return self._cached_cameras

    def force_full_scan(self, max_cameras=20):
        """
        Clear cache and perform a full robust scan of all potential devices.
        """
        logging.info("Forcing FULL camera scan...")
        
        # 1. Discovery (Hybrid: v4l2-ctl + glob)
        candidates = []
        
        # Try v4l2-ctl first (Fastest)
        v4l2_devices = []
        try:
            result = subprocess.run(['v4l2-ctl', '--list-devices'], capture_output=True, text=True)
            if result.returncode == 0:
                output = result.stdout
                paths = re.findall(r'/dev/video(\d+)', output)
                v4l2_devices = sorted(list(set([int(p) for p in paths])))
                logging.info(f"v4l2-ctl found: {v4l2_devices}")
        except Exception as e:
            logging.warning(f"v4l2-ctl scan failed: {e}")

        if v4l2_devices:
            candidates = v4l2_devices
        else:
            # Fallback to glob
            candidates = self.get_all_video_devices()
            # Also check by-id if available
            by_id_path = "/dev/v4l/by-id"
            if os.path.exists(by_id_path):
                for path in glob.glob(os.path.join(by_id_path, "*")):
                    try:
                        real_path = os.path.realpath(path)
                        idx = int(re.search(r'video(\d+)', real_path).group(1))
                        candidates.append(idx)
                    except:
                        pass
            
            # Helper: Add standard range if empty
            if not candidates:
                 candidates = list(range(max_cameras))
        
        # Deduplicate candidates
        candidates = sorted(list(set(candidates)))
        
        # 2. Probe
        self._cached_cameras = self._probe_candidates(candidates)
        self._all_video_devices = candidates # approximate
        self._last_scan_time = time.time()
        
        return self._cached_cameras

    def _probe_candidates(self, candidates):
        """Internal method to probe a list of candidate indices"""
        working_cameras = []
        logging.info(f"Probing candidates: {candidates}")
        
        for i in candidates:
            # Capability Check (Optimization)
            is_capture = True
            try:
                # Check sysfs name for 'meta'/'output' words to skip obvious non-cameras
                if os.path.exists(f"/sys/class/video4linux/video{i}/name"):
                    with open(f"/sys/class/video4linux/video{i}/name", 'r') as f:
                        name = f.read().lower()
                        if any(x in name for x in ["meta", "output", "subdev", "stats", "params"]):
                             # Double check with v4l2-ctl to be safe, or just skip if very confident
                             pass 
            except:
                pass

            # V4L2-CTL Check
            try:
                res_fmt = subprocess.run(['v4l2-ctl', f'--device={i}', '--get-fmt-video'], capture_output=True, text=True)
                if res_fmt.returncode != 0:
                    is_capture = False
                else:
                    res_cap = subprocess.run(['v4l2-ctl', f'--device={i}', '--all'], capture_output=True, text=True)
                    if "Video Capture" not in res_cap.stdout:
                         is_capture = False
            except:
                pass
            
            if not is_capture:
                continue

            # OpenCV Open Test
            try:
                # fast open with V4L2
                cap = cv.VideoCapture(i, cv.CAP_V4L2)
                if not cap.isOpened():
                    cap = cv.VideoCapture(i) # Fallback
                
                if cap.isOpened():
                    cap.set(cv.CAP_PROP_BUFFERSIZE, 1)
                    # Quick read test
                    ret, frame = cap.read()
                    if ret and frame is not None and frame.size > 0:
                         if i not in working_cameras:
                             working_cameras.append(i)
                             logging.info(f"Confirmed working camera: video{i}")
                    cap.release()
            except Exception as e:
                logging.debug(f"Failed to probe video{i}: {e}")
                
        return sorted(working_cameras)


# Global instance
manager = CameraManager()

# --- Legacy/Wrapper Functions ---

def find_available_cameras(max_cameras=20):
    """
    Wrapper for backward compatibility. 
    NOTE: Users of this function might expect a fresh list.
    However, for performance, we should clarify if we return cached or new.
    The existing code calls this on refresh.
    We will map this to `force_full_scan` to maintain original behavior (slow but accurate),
    OR we can map to `get_cached_cameras` if we assume the caller handles refresh separately.
    
    Given the new architecture, `find_available_cameras` is likely called by the startup script.
    Let's make it ensure the cache is initialized, then return it.
    """
    if not manager.get_cached_cameras() and manager._last_scan_time == 0:
        return manager.force_full_scan(max_cameras)
    return manager.get_cached_cameras()

def refresh_camera_detection(max_cameras=20, mode='full'):
    """
    New entry point with mode support.
    mode: 'full' (default, slow) or 'new' (fast)
    """
    if mode == 'new':
        return manager.scan_new_cameras()
    else:
        return manager.force_full_scan(max_cameras)

def test_camera_connection(camera_index):
    """Test specific camera (stateless)"""
    try:
        cap = cv.VideoCapture(camera_index, cv.CAP_V4L2)
        if not cap.isOpened():
             cap = cv.VideoCapture(camera_index)
        
        if cap.isOpened():
            cap.set(cv.CAP_PROP_BUFFERSIZE, 1)
            time.sleep(0.1)
            ret, frame = cap.read()
            cap.release()
            if ret and frame is not None and frame.size > 0:
                return True, f"Camera {camera_index} OK"
            return False, "No frames"
        return False, "Could not open"
    except Exception as e:
        return False, str(e)

def initialize_camera(camera_index):
    """Initialize camera object (stateless)"""
    try:
        cap = cv.VideoCapture(camera_index, cv.CAP_V4L2)
        if not cap.isOpened():
            cap = cv.VideoCapture(camera_index)
        
        if cap.isOpened():
            ret, _ = cap.read()
            if ret:
                return cap
            cap.release()
    except:
        pass
    return None

if __name__ == "__main__":
    print("Testing CameraManager...")
    manager.initialize_cache()
    print(f"Cached: {manager.get_cached_cameras()}")
    print("Testing Scan New...")
    print(f"Result: {manager.scan_new_cameras()}")