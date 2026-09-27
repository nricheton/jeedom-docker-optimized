#!/bin/bash


PLUGIN_NAME=$1
PLUGIN_DIR="/tmp/plugins/$PLUGIN_NAME"
ARCH=$(uname -m)

if [ -z "$PLUGIN_NAME" ]; then
    echo "Error: Plugin name not provided."
    exit 1
fi

if [ -d "$PLUGIN_DIR" ]; then
    cd "$PLUGIN_DIR"
    if [ -f "$PLUGIN_NAME-$ARCH.sh" ]; then
        echo "Running architecture-specific script: $PLUGIN_NAME-$ARCH.sh"
        chmod +x "$PLUGIN_NAME-$ARCH.sh"
        ./"$PLUGIN_NAME-$ARCH.sh"
        RESULT=$?
    elif [ -f "$PLUGIN_NAME.sh" ]; then
        echo "Running default script: $PLUGIN_NAME.sh"
        chmod +x "$PLUGIN_NAME.sh"
        ./"$PLUGIN_NAME.sh"
        RESULT=$?
    else
        echo "Error: No installation script found for plugin $PLUGIN_NAME."
        exit 1
    fi
    cd /tmp
    rm -rf "$PLUGIN_DIR"
    if [ $RESULT -ne 0 ]; then
        echo "Error: installation of plugin $PLUGIN_NAME failed (exit code $RESULT)."
        exit $RESULT
    fi
else
    echo "Error: Plugin directory $PLUGIN_DIR does not exist."
    exit 1
fi