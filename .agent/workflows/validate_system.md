---
description: System Validation Workflow (Uninstall -> Install -> Verify)
---

# Full System Validation Workflow

This workflow validates the entire installation and execution lifecycle of **theSmallComparator**, ensuring clean state, dependency correctness, and runtime stability.

## 1. Clean Uninstall
Ensure the system is completely clean of previous installations.

```bash
cd dependencies
chmod +x uninstall.sh
./uninstall.sh --remove-all
cd ..
```

**Verification:**
-   Service `theSmallComparator.service` should not exist.
-   Command `theSmallComparator` should be removed.

## 2. Full Installation
Run the unified installer to set up the environment.

```bash
chmod +x install.sh
./install.sh
```

**Steps to select:**
-   Choose Option 1 (Install).
-   System will detect OS (Linux/RPi).
-   If asked for Auto-Start service, choose **NO** (n) for validation purposes to test manual start first.

**Verification:**
-   `setup_env/` directory created?
-   Dependencies installed without errors?
-   `theSmallComparator` command created in `/usr/local/bin`?

## 3. Runtime Verification
Start the application manually to check for immediate crash loops or missing imports.

```bash
# Start in background or separate terminal
theSmallComparator &
PID=$!
sleep 5
```

## 4. Operational Check
Verify the server is responding and API is functional.

```bash
# Check status endpoint
// turbo
curl -v http://localhost:5001/api/status
```

**Expected Result:**
-   HTTP 200 OK
-   JSON response containing `"connected": true`
-   `"mode"` should be `"GRBL"`, `"Klipper"`, or `"Disconnected"` (not error).

## 5. Klipper/GRBL Mode Check
If you have a Klipper instance running (e.g. on port 7125):
-   Verify `mode` is `"Klipper"`.
-   Verify UI shows Blue Badge.

If you have a GRBL board connected:
-   Verify `mode` is `"GRBL"`.
-   Verify UI shows Serial Connection panel.

## 6. Cleanup (Stop Server)
```bash
kill $PID
```
