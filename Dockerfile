ARG PYTHON_VERSION=3.11

FROM python:${PYTHON_VERSION}-slim

RUN pip install jupyterlab

# Don't ask about Jupyter news
# https://stackoverflow.com/a/75552789
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

ENTRYPOINT ["jupyter", "lab", "/tmp", "--NotebookApp.shutdown_button=True", "--IdentityProvider.token=''", "--no-browser", "--ip", "0.0.0.0", "--port", "8888", "--allow-root"]
