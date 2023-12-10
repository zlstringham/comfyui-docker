FROM nvidia/cuda:12.1.0-devel-ubuntu22.04
ARG TARGETPLATFORM

ENV CUDA_HOME=/usr/local/cuda

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md#example-cache-apt-packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-${TARGETPLATFORM} <<EOT
    set -ex
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y \
        build-essential \
        curl \
        ffmpeg \
        git \
        libgl1 \
        libglib2.0-0 \
        python3 \
        python3-opencv \
        python3-packaging \
        python3-pip \
        python3-venv \
        wget
    rm -rf /var/lib/apt/lists/*

    groupadd -g 1000 comfyui
    useradd -d /app -u 1000 -g comfyui comfyui
    chown -R comfyui:comfyui /app
EOT

USER comfyui:comfyui
ENV PATH="/app/.local/bin:${PATH}"

# Arg to invalidate cached git clone step
ARG GIT_CLONE_CACHE
RUN --mount=type=cache,uid=1000,gid=1000,target=/app/.cache/pip,sharing=locked,id=pip-${TARGETPLATFORM} <<EOT
    set -ex
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git
    pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121
    pip install -r ComfyUI/requirements.txt

    mv ComfyUI/input input
    mv ComfyUI/models models
    mv ComfyUI/web/extensions web_extensions

    mkdir -p ComfyUI/input
    mkdir -p ComfyUI/models
    mkdir -p ComfyUI/web/extensions
    mkdir -p ComfyUI/venv
EOT

VOLUME /app/ComfyUI/custom_nodes
VOLUME /app/ComfyUI/input
VOLUME /app/ComfyUI/models
VOLUME /app/ComfyUI/output
VOLUME /app/ComfyUI/venv
VOLUME /app/ComfyUI/web/extensions

ARG PORT=8188
ENV PORT=${PORT}
EXPOSE ${PORT}

COPY --chmod=775 --chown=comfyui:comfyui ./entrypoint.sh .
ENTRYPOINT ["./entrypoint.sh"]
