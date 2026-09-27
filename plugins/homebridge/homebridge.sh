#!/bin/bash
set -e

echo "Running additional setup for Homebridge..."
# Progress/log folder used by dependance.lib (normally created by Jeedom)
mkdir -p /tmp/jeedom/plugins
chmod u+x ./install_homebridge.sh
./install_homebridge.sh
