#!/bin/bash
######################### INCLUSION LIB ##########################
BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
wget https://raw.githubusercontent.com/NebzHB/dependance.lib/master/dependance.lib -O $BASEDIR/dependance.lib &>/dev/null
PLUGIN=$(basename "$(realpath $BASEDIR/..)")
. ${BASEDIR}/dependance.lib
##################################################################
wget https://raw.githubusercontent.com/NebzHB/nodejs_install/main/install_nodejs.sh -O $BASEDIR/install_nodejs.sh &>/dev/null

installVer='14' 	#NodeJS major version to be installed

pre
step 0 "Vérification des droits"
silent sudo killall homebridge
DIRECTORY="/var/www"
if [ ! -d "$DIRECTORY" ]; then
	silent sudo mkdir $DIRECTORY
fi
silent sudo chown -R www-data $DIRECTORY

step 5 "Mise à jour APT et installation des packages nécessaires"
try sudo apt-get update
try sudo DEBIAN_FRONTEND=noninteractive apt-get install -y avahi-daemon avahi-discover avahi-utils libnss-mdns libavahi-compat-libdnssd-dev dialog

#install nodejs, steps 10->50
. ${BASEDIR}/install_nodejs.sh ${installVer}

step 60 "Nettoyage anciens modules"
sudo npm ls -g --depth 0 2>/dev/null | grep "homebridge@" >/dev/null 
if [ $? -ne 1 ]; then
  echo "[Suppression homebridge global"
  silent sudo npm rm -g homebridge
fi
cd ${BASEDIR};
#remove old local modules
sudo rm -rf node_modules &>/dev/null
sudo rm -f package-lock.json &>/dev/null

if [ -n $2 ]; then
	BRANCH=$2
else
	BRANCH="master"
fi

step 70 "Installation de Homebridge ${BRANCH}, veuillez patienter svp"
#need to be sudoed because of recompil
silent sudo mkdir node_modules
silent sudo chown -R www-data:www-data .

try sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm -g homebridge-camera-ffmpeg@latest
try sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm -g homebridge-alexa@latest
try sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm -g bonjour@3.5.0
try sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm -g homebridge-gsh@2.1.0
try sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm -g homebridge-config-ui-x@latest

#install homebridge
try sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm
cd node_modules
try sudo -E -n git clone -b ${BRANCH} https://github.com/NebzHB/homebridge-jeedom.git
cd homebridge-jeedom
try sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm
cd ..
cd ..

silent sudo chown -R www-data:www-data .
#authorize www-data to use the video device (/dev/vchiq on RPI or video accelerator)
silent sudo usermod -aG video www-data


testGMP=$(php -r "echo extension_loaded('gmp');")
silent sudo service php5-fpm status
nginxPresent=$?
if [[ "$testGMP" != "1" ]]; then
  if [[ "$nginxPresent" != "0" ]]; then
    step 80 "Installation de l'extension gmp pour le QRCode"
    silent sudo DEBIAN_FRONTEND=noninteractive apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y php-gmp
  
    silent sudo service apache2 status
    if [ $? = 0 ]; then
      echo "Reload apache2..."
      silent sudo systemctl daemon-reload
      silent sudo systemctl reload apache2.service || silent sudo service apache2 reload
    fi
  fi
fi

step 90 "Configuration Avahi"
if [ -f /media/boot/multiboot/meson64_odroidc2.dtb.linux ]; then
  echo "Désactivation de avahi-daemon au démarrage...(il démarrera avec le daemon (on contourne le bug de la Smart du 1 jan 1970))"
  silent sudo systemctl disable avahi-daemon
fi
silent sudo sed -i "/.*enable-dbus.*/c\enable-dbus=yes  #changed by homebridge" /etc/avahi/avahi-daemon.conf
silent sudo sed -i "/.*use-ipv6.*/c\use-ipv6=no  #changed by homebridge" /etc/avahi/avahi-daemon.conf
#sudo sed -i "/.*publish-aaaa-on-ipv4.*/c\publish-aaaa-on-ipv4=yes  #changed by homebridge" /etc/avahi/avahi-daemon.conf
#sudo sed -i "/.*publish-a-on-ipv6.*/c\publish-a-on-ipv6=no  #changed by homebridge" /etc/avahi/avahi-daemon.conf
if [ -n $1 ]; then
	UsedEth=$(ip addr | grep $1 | awk '{print $7}')
	silent sudo sed -i "/.*allow-interfaces.*/c\#allow-interfaces=$UsedEth  #changed by homebridge" /etc/avahi/avahi-daemon.conf
fi

post
