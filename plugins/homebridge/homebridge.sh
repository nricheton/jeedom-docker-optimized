#!/bin/bash

echo "Running additional setup for Homebridge..."
cd /tmp/homebridge/resources
chmod u+x ./install_homebridge.sh
./install_homebridge.sh
