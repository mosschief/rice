#!/usr/bin/env python3
import sys
import json
import struct
import os
import time

def send(message):
    msg = json.dumps(message).encode('utf-8')
    sys.stdout.buffer.write(struct.pack('@I', len(msg)))
    sys.stdout.buffer.write(msg)
    sys.stdout.buffer.flush()

theme_file = os.path.expanduser('~/.config/sway/current-theme')
last_mtime = None

# Send initial theme on connect
try:
    with open(theme_file) as f:
        send({'theme': f.read().strip()})
    last_mtime = os.path.getmtime(theme_file)
except Exception:
    pass

while True:
    try:
        mtime = os.path.getmtime(theme_file)
        if mtime != last_mtime:
            last_mtime = mtime
            with open(theme_file) as f:
                send({'theme': f.read().strip()})
    except Exception:
        pass
    time.sleep(0.3)
