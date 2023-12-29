#!/bin/bash

# Read LIB_DIRS and export it to LD_LIBRARY_PATH
NV_LIB_DIRS=$(cat /opt/app/nv_lib_dirs.conf)
export LD_LIBRARY_PATH="$NV_LIB_DIRS:$LD_LIBRARY_PATH"

# Execute the main command
exec "$@"
