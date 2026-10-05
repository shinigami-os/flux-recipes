#!/usr/bin/env python3
import glob
import subprocess
import sys

PROBE = """
import sys
import cv2
cap = cv2.VideoCapture(sys.argv[1], cv2.CAP_V4L2)
ok = cap.isOpened() and cap.read()[0]
cap.release()
sys.exit(0 if ok else 1)
"""

for path in sorted(glob.glob("/dev/video*")):
    try:
        result = subprocess.run([sys.executable, "-c", PROBE, path], timeout=20,
                                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.TimeoutExpired:
        continue
    if result.returncode == 0:
        print(path)
        break
