FROM nvidia/cuda:12.3.1-base-ubuntu22.04

ARG PORT=8188
ENV PORT=${PORT}

ENV CUDA_HOME=/usr/local/cuda

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

EXPOSE ${PORT}
WORKDIR /app

# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md#example-cache-apt-packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked <<EOT
    set -ex
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
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
# Invalidate cache if latest commit changes
ADD "https://api.github.com/repos/comfyanonymous/ComfyUI/commits?per_page=1" latest_commit
RUN --mount=type=cache,uid=1000,gid=1000,target=/app/.cache/pip,sharing=locked <<EOT
    set -ex
    rm latest_commit
    git clone https://github.com/comfyanonymous/ComfyUI.git    
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

HEALTHCHECK CMD curl -f http://localhost:${PORT} || exit 1

USER root
COPY ./entrypoint.sh .
RUN chmod +x entrypoint.sh

USER comfyui:comfyui
ENTRYPOINT ["./entrypoint.sh"]
