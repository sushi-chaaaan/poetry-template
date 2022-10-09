#!/bin/bash
if [ "$(uname)" = "Darwin" ]; then
    echo "macOS"
elif [[ "$(uname -r)" = *"WSL"* ]]; then
    echo "WSL"
elif [ "$(uname)" = "Linux" ]; then
    echo "Linux"
fi
