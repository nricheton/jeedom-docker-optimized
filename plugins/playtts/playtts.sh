#!/bin/bash


echo "Running additional setup for PlayTTS..."
apt-get install --no-install-recommends -y libsox-fmt-mp3 sox libttspico-utils mplayer mpg123 lsb-release software-properties-common
cd /tmp
git clone https://github.com/lunarok/jeedom_playtts.git
cd jeedom_playtts && git checkout master && cd resources
sed -i 's/sudo usermod -a -G audio `whoami`/sudo usermod -a -G audio www-data/' ./install.sh
chmod u+x ./install.sh
./install.sh
