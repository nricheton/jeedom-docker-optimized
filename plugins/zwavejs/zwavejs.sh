#!/bin/bash

echo "Running additional setup for  Z-Wave js plugin..."

git clone https://github.com/jeedom/plugin-zwavejs.git
cd plugin-zwavejs && git checkout master && cd resources
# chmod u+x ./install_apt.sh
#./install_apt.sh
