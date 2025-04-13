#!/bin/bash


echo "Running additional setup for open Z-Wave plugin..."
cd /tmp
git clone https://github.com/jeedom/plugin-openzwave.git
cd plugin-openzwave && git checkout master && cd resources
chmod u+x ./install_apt.sh
./install_apt.sh
