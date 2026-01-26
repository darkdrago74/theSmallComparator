
import serial.tools.list_ports
import cv2
import os
import time

print("=== SERIAL PORTS ===")
ports = serial.tools.list_ports.comports()
if not ports:
    print("No serial ports found!")
else:
    for p in ports:
        print(f"Device: {p.device}")
        print(f"  Name: {p.name}")
        print(f"  Desc: {p.description}")
        print(f"  HWID: {p.hwid}")
        print(f"  VID: {p.vid}, PID: {p.pid}")
        print("-" * 20)

print("\n=== CAMERAS ===")
# List video devices
video_devs = [f for f in os.listdir('/dev') if f.startswith('video')]
video_devs.sort()
print(f"Found /dev entries: {video_devs}")

print("\n=== SERIAL CONNECTION TEST ===")
try:
    import serial
    target_port = '/dev/ttyUSB0'
    print(f"Attempting to open {target_port}...")
    ser = serial.Serial(target_port, 115200, timeout=2)
    print("  Port opened successfully!")
    
    # Toggle DTR to reset Arduino (optional, sometimes helps)
    ser.dtr = False
    time.sleep(0.1)
    ser.dtr = True
    time.sleep(2) # Wait for potential bootloader
    
    # Send status command
    print("  Sending '?' command...")
    ser.write(b'?\n')
    time.sleep(0.5)
    
    if ser.in_waiting:
        resp = ser.read_all().decode('utf-8', errors='ignore')
        print(f"  Response received: {resp.strip()}")
    else:
        print("  No response received (Device might be silent or unpowered)")
        
    ser.close()
    print("  Port closed.")
except Exception as e:
    print(f"  ERROR: {e}")

print("\n=== CAMERA TEST (Linear) ===")
import time
# Try video0 and video11 specifically since we know them
targets = [0, 11, 14, 15]

for i in targets:
    print(f"Testing video{i}...")
    cap = cv2.VideoCapture(i, cv2.CAP_V4L2)
    if cap.isOpened():
        print(f"  video{i}: OPENED")
        ret, frame = cap.read()
        if ret:
            print(f"  video{i}: FRAME CAPTURED ({frame.shape})")
        else:
            print(f"  video{i}: OPENED BUT NO FRAME")
        cap.release()
    else:
        print(f"  video{i}: FAILED TO OPEN")
        # Try without V4L2 flag
        cap = cv2.VideoCapture(i)
        if cap.isOpened():
             print(f"  video{i} (default backend): OPENED")
             cap.release()
        else:
             print(f"  video{i} (default backend): FAILED")

print("Done.")
