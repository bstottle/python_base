ARG PYTHON_VERSION=3.11

# The 'slim' is smaller version, 'bookworm' is Debian 12.  We could just use 'slim', but we should
# be explicit about any change to the OS version.
FROM python:${PYTHON_VERSION}-slim-bookworm

RUN pip install --upgrade pip && \
    pip install jupyterlab torch torchvision torchaudio

# Don't ask about Jupyter news
# https://stackoverflow.com/a/75552789
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

ENTRYPOINT ["jupyter", "lab", "/tmp", "--NotebookApp.shutdown_button=True", "--IdentityProvider.token=''", "--no-browser", "--ip", "0.0.0.0", "--port", "8888", "--allow-root"]
