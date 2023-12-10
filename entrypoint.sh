#!/bin/bash

cd /app/ComfyUI

cp -rn ../input/* input/
cp -rn ../models/* models/
cp -rn ../web_extensions/* web/extensions/

[ -z "${PYTORCH_CUDA_ALLOC_CONF}" ] && unset PYTORCH_CUDA_ALLOC_CONF

if ! [ -f "venv/bin/activate" ]; then
    echo 'Creating virtual environment...'
    python3 -m venv venv --system-site-packages
fi
echo 'Activating virtual environment...'
source venv/bin/activate

set -x
exec python3 main.py "$@" --listen --port ${PORT:-8188}
