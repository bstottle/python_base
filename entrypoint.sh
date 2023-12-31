#!/bin/bash

# Read LIB_DIRS and export it to LD_LIBRARY_PATH
NV_LIB_DIRS=$(cat /opt/app/nv_lib_dirs.conf)
export LD_LIBRARY_PATH="$NV_LIB_DIRS:$LD_LIBRARY_PATH"

# Path where initial content is stored in the image
INIT_CONTENT="/examples"

# Path of the mounted volume
VOLUME_PATH="/app"

# Function to check if the first command starts with "jupyter"
starts_with_jupyter() {
    local command=$1
    [[ "$command" == jupyter* ]]
}

# If the command starts with "jupyter", perform the copy operation
if starts_with_jupyter "$1"; then
    echo "Starting Jupyter - copying initial content if needed..."
    cp -u $INIT_CONTENT/* $VOLUME_PATH/
else
    echo "Not starting Jupyter - skipping copy of initial content."
fi

# Continue with the main container process
exec "$@"
