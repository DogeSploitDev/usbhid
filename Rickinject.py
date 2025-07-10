#!/usr/bin/env python3
import time
import os
import subprocess

DEV = '/dev/hidg0'
NULL = b'\x00' * 8

# HID code mapping
GUI = 0x08
L_KEY = 0x0F
ENTER = 0x28

def send(mod=0, kc=0):
    with open(DEV, 'wb') as f:
        f.write(bytes([mod, 0, kc, 0,0,0,0,0]))
    time.sleep(0.05)
    with open(DEV, 'wb') as f:
        f.write(NULL)
    time.sleep(0.05)

def type_string(s):
    for c in s:
        kc = ord(c.lower()) - 93 if 'a' <= c <= 'z' else ord(c)
        send(0, kc)

def gadget_present():
    return os.path.exists(DEV)

def focus_detected():
    try:
        out = subprocess.check_output(['xinput', 'list'], stderr=subprocess.DEVNULL).decode()
        return True if 'Virtual core keyboard' in out else False
    except:
        return False

# Wait for gadget
print("Waiting for HID gadget to appear...", end='', flush=True)
for _ in range(60):
    if gadget_present():
        print(" found.")
        break
    print(".", end='', flush=True)
    time.sleep(0.5)
else:
    print("\nError: HID gadget not found.")
    exit(1)

# Optional focus check
print("Checking OS-level recognition...", end='', flush=True)
for _ in range(20):
    if focus_detected():
        print(" OK.")
        break
    print(".", end='', flush=True)
    time.sleep(0.25)
else:
    print("\nWarning: OS may not recognize keyboard yet.")

time.sleep(1)

# Inject sequence: GUI+L, URL, Enter
send(GUI, L_KEY)
time.sleep(0.3)

url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
print(f"Typing URL: {url}")
type_string(url)

send(0, ENTER)
print("Enter sent.")

print("✅ Injection completed.")
