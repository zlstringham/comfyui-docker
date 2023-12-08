FROM nvidia/cuda:12.3.1-base-ubuntu22.04

ENV CUDA_HOME=/usr/local/cuda

EXPOSE 8188
WORKDIR /app

# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md#example-cache-apt-packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked <<EOT
    set -ex
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git \
        python3 \
        python3-pip \
        python3-venv

    groupadd -g 1000 comfyui
    useradd -d /app -u 1000 -g comfyui comfyui
    chown -R comfyui:comfyui /app
EOT

USER comfyui:comfyui
ENV PATH="/app/.local/bin:${PATH}"
RUN --mount=type=cache,uid=1000,gid=1000,target=/app/.cache/pip,sharing=locked <<EOT
    set -ex
    git clone https://github.com/comfyanonymous/ComfyUI.git
    pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121
    pip install -r ComfyUI/requirements.txt
EOT

USER root
COPY ./entrypoint.sh .
RUN chmod +x entrypoint.sh

USER comfyui:comfyui
ENTRYPOINT ["./entrypoint.sh", "--listen"]
