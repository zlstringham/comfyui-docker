#!/bin/bash

cd /app/ComfyUI

! [ "$(ls -A input)" ] && cp -r ../input/* input/
! [ "$(ls -A models)" ] && cp -r ../models/* models/
! [ "$(ls -A web/extensions)" ] && cp -r ../web_extensions/* web/extensions/

! [ -f "venv/bin/activate" ] && python3 -m venv venv --system-site-packages
source venv/bin/activate

exec python3 main.py "$@"
