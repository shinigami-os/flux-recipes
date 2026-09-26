#!/usr/bin/env python3
import cv2
import glob

for path in sorted(glob.glob("/dev/video*")):
    cap = cv2.VideoCapture(path)
    opened = cap.isOpened()
    ok = False
    if opened:
        ok, _ = cap.read()
    cap.release()
    if opened and ok:
        print(path)
        break
