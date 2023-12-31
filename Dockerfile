ARG PYTHON_VERSION=3.11

# The 'slim' is smaller version, 'bookworm' is Debian 12.  We could just use 'slim', but we should
# be explicit about any change to the OS version.
################################################
# builder image ################################
################################################
FROM python:${PYTHON_VERSION}-bookworm as builder

ENV PYTHONDONTWRITEBYTECODE 1 \
    PYTHONUNBUFFERED 1

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y wget gnupg software-properties-common && \
    #################### NVIDIA ####################
    # We are getting pytorch for CUDA 12.1, while the debian 12 repo only has CUDA 12.3.
    # Install necessary packages for adding repositories
    # Add NVIDIA package repositories
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/3bf863cc.pub && \
    echo "deb http://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/ /" > /etc/apt/sources.list.d/cuda.list && \
    # Add NVIDIA non-free/contrib
    echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    apt-get update && \
    # List available versions of CUDA (optional step for information)
    apt-cache madison cuda && \
    # Install CUDA
    apt-get install -y cuda=12.3.1-1

# Set environment variables
ENV PATH=/usr/local/cuda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}
#################### NVIDIA ####################

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

ARG CMAKE_ARGS="-DLLAMA_CUBLAS=on"
ARG FORCE_CMAKE=1
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install torch torchvision torchaudio gradio cmake ninja \
    # Chat specific modules
    ctransformers[cuda] langchain llama-cpp-python hf_transfer \
    # Image specific modules
    diffusers transformers accelerate omegaconf invisible-watermark>=0.2.0

################################################
# final image ##################################
################################################
FROM python:${PYTHON_VERSION}-slim-bookworm

ENV NVIDIA_DRIVER_CAPABILITIES="all"

COPY entrypoint.sh /entrypoint.sh

RUN addgroup --system app && adduser --system --home /home/app --group app && \
    mkdir /opt/app && chown app:app /opt/app && chmod 755 /opt/app && \
    chmod +x /entrypoint.sh && \
    apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0

USER app

COPY --from=builder /opt/venv /opt/venv
COPY --chown=app:app examples /examples

WORKDIR /app
COPY --chown=app:app jupyter_settings .jupyter

# Pip locations step #2 (to enable user install python packages in a volume)
# We create a /app/venv directory with a 2nd venv in it.  This is the one available for exposing as
# a volume.  We ensure all of the read-only python modules are available by adding a .pth file
# pointing to the initially created venv at /home/app/venv.  The sysconfig finds the full path,
# including the python version.
RUN python -m venv /app/venv && \
    # Make the derived virtual environment import base's packages too.
    base_site_packages="$(/opt/venv/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')" && \
    derived_site_packages="$(/app/venv/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')" && \
    echo "$base_site_packages" > "$derived_site_packages"/root_packages.pth && \
    # Gather the locations for nvidia shared libs so we can add them to LD_LIBRARY_PATH
    NV_LD_PATHS=$(echo "import os; print(':'.join(sorted({path+'/lib' for path, dirs, _ in os.walk('$base_site_packages/nvidia') if 'lib' in dirs})))" | python) && \
    echo $NV_LD_PATHS > /opt/app/nv_lib_dirs.conf

ENV PATH="/app/venv/bin:/opt/venv/bin:$PATH" \
    HF_HUB_CACHE="/app/data/.hub_cache" \
    JUPYTER_CONFIG_DIR="/app/.jupyter" \
    SHELL=/bin/bash

RUN --mount=type=cache,target=~/.cache/pip \
    pip install --no-cache jupyterlab ipywidgets

# Don't ask about Jupyter news
# https://stackoverflow.com/a/75552789
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

ENTRYPOINT ["/entrypoint.sh"]

CMD [ "jupyter", "lab", \
      "/app", \
      "--IdentityProvider.token=''", \
      "--ip", "0.0.0.0", \
      "--port", "8888", \
      "--no-browser" \
    ]
