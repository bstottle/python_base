ARG PYTHON_VERSION=3.11

# The 'slim' is smaller version, 'bookworm' is Debian 12.  We could just use 'slim', but we should
# be explicit about any change to the OS version.
FROM python:${PYTHON_VERSION}-bookworm as builder

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN pip install --upgrade pip
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN --mount=type=cache,target=/root/.cache/pip pip install torch torchvision torchaudio

# final image
FROM python:${PYTHON_VERSION}-slim-bookworm

COPY entrypoint.sh /entrypoint.sh

RUN addgroup --system app && adduser --system --home /home/app --group app && \
    mkdir /opt/app && chown app:app /opt/app && chmod 755 /opt/app && \
    chmod +x /entrypoint.sh

USER app

COPY --from=builder /opt/venv /opt/venv

WORKDIR /app

# Pip locations step #2 (to enable user install python packages in a volume)
# We create a /app/venv directory with a 2nd venv in it.  This is the one available for exposing as
# a volume.  We ensure all of the read-only python modules are available by adding a .pth file
# pointing to the initially created venv at /home/app/venv.  The sysconfig finds the full path,
# including the python version.
RUN python -m venv /app/venv && \
    # Make the derived virtual environment import base's packages too.
    base_site_packages="$(/opt/venv/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')" && \
    derived_site_packages="$(/app/venv/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')" && \
    echo "$base_site_packages" > "$derived_site_packages"/root_packages.pth

ENV PATH="/app/venv/bin:$PATH"

RUN pip install --no-cache jupyterlab

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
