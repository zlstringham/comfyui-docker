FROM nvidia/cuda:12.3.1-base-ubuntu22.04

ENV CUDA_HOME=/usr/local/cuda

EXPOSE 8188
WORKDIR /app

# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md#example-cache-apt-packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache/pip,sharing=locked <<EOT
    set -ex
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git \
        python3 \
        python3-pip \
        python3-venv

    git clone https://github.com/comfyanonymous/ComfyUI.git
    pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121
    pip install -r ComfyUI/requirements.txt
EOT

COPY ./entrypoint.sh .
RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh", "--listen"]
