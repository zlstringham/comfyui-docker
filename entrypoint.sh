#!/bin/bash

cd /app/ComfyUI

! [ -f "venv/bin/activate" ] && python3 -m venv venv --system-site-packages
source venv/bin/activate

exec python3 main.py "$@"
