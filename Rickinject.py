#!/usr/bin/env python3
import time
def send(b): open('/dev/hidg0','wb').write(b)
NULL = b'\x00' * 8
def key(ctrl, code): return bytes([ctrl,0,code,0,0,0,0,0])

time.sleep(2)
send(key(0x08, 0x15)); send(NULL)  # Win+R
time.sleep(0.5)
for c in b'https://www.youtube.com/watch?v=dQw4w9WgXcQ':
    send(key(0, c)); send(NULL)
send(key(0, 0x28)); send(NULL)  # Enter
