#!/bin/bash
######################### INCLUSION LIB ##########################
BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
wget -4 https://raw.githubusercontent.com/NebzHB/dependance.lib/master/dependance.lib -O $BASEDIR/dependance.lib &>/dev/null
PLUGIN=$(basename "$(realpath $BASEDIR/..)")
TIMED=1
. ${BASEDIR}/dependance.lib
##################################################################
wget -4 https://raw.githubusercontent.com/NebzHB/dependance.lib/master/install_nodejs.sh -O $BASEDIR/install_nodejs.sh &>/dev/null

pre
step 0 "Vérification des droits"

#init arguments
forceNodeVersion=""
interface="eth0"
BRANCH="master"
noGSH=false
noAlexa=false
noCam=false
noSupport=false

while [[ "$#" -gt 0 ]]; do
	case $1 in
		--forceNodeVersion) forceNodeVersion="--forceNodeVersion $2"; shift ;; #NodeJS version to be installed
		--interface) interface="$2"; shift ;;
		--branch) BRANCH="$2"; shift ;;
		--noGSH) noGSH=true ;;
		--noAlexa) noAlexa=true ;;
		--noCam) noCam=true ;;
  		--noSupport) noSupport=true ;;
		*) echo "Option inconnue: $1"; tryOrStop false ;;
	esac
	shift
done

silent sudo killall homebridge
DIRECTORY="/var/www"
if [ ! -d "$DIRECTORY" ]; then
	silent sudo mkdir $DIRECTORY
fi
silent sudo chown -R www-data $(realpath $BASEDIR/..)

step 5 "Mise à jour APT et installation des packages nécessaires"
tryOrStop sudo apt-get -o Acquire::ForceIPv4=true update
try sudo DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::ForceIPv4=true install -y avahi-daemon avahi-discover avahi-utils libnss-mdns libavahi-compat-libdnssd-dev dialog

#install nodejs, steps 10->50
. ${BASEDIR}/install_nodejs.sh --firstSubStep 10 --lastSubStep 50 ${forceNodeVersion}

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

step 70 "Vérification des droits avant install"
silent sudo mkdir node_modules
silent sudo chown -R www-data:www-data .

if [ "$noCam" = true ]; then
	step 72 "Suppression homebridge-camera-ffmpeg si existant"
	silent sudo -E -n npm uninstall -g homebridge-camera-ffmpeg
else
	step 72 "Installation/Mise à jour de homebridge-camera-ffmpeg"
	try sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm -g homebridge-camera-ffmpeg@latest
fi
if [ "$noAlexa" = true ]; then
	step 74 "Suppression homebridge-alexa si existant"
	silent sudo -E -n npm uninstall -g homebridge-alexa
else
	step 74 "Installation/Mise à jour de homebridge-alexa"
	try sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm -g homebridge-alexa@latest
fi
if [ "$noGSH" = true ]; then
	step 76 "Suppression homebridge-gsh si existant"
	silent sudo -E -n npm uninstall -g homebridge-gsh
	silent sudo -E -n npm uninstall -g bonjour
else
	step 76 "Installation/Mise à jour de homebridge-gsh"
	try sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm -g bonjour@3.5.0
	try sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm -g homebridge-gsh@latest
fi
step 78 "Installation/Mise à jour de homebridge-config-ui-x"
tryOrStop sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm -g homebridge-config-ui-x@latest

#install homebridge
step 80 "Installation de Homebridge"
tryOrStop sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm

step 82 "Installation de homebridge-jeedom ${BRANCH}, veuillez patienter svp"
cd node_modules
tryOrStop sudo -E -n git clone -b ${BRANCH} https://github.com/NebzHB/homebridge-jeedom.git
cd homebridge-jeedom
tryOrStop sudo -E -n npm install --no-fund --no-package-lock --no-audit --unsafe-perm
cd ..
cd ..

step 84 "Vérification des droits après install"
silent sudo chown -R www-data:www-data .
#authorize www-data to use the video device (/dev/vchiq on RPI or video accelerator)
silent sudo usermod -aG video www-data

testGMP=$(php -r "echo extension_loaded('gmp');")
silent sudo service php5-fpm status
nginxPresent=$?
if [[ "$testGMP" != "1" ]]; then
  if [[ "$nginxPresent" != "0" ]]; then
    step 86 "Installation de l'extension gmp pour le QRCode"
    silent sudo DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::ForceIPv4=true install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y php-gmp
  
    silent sudo service apache2 status
    if [ $? = 0 ]; then
      step 88 "Reload apache2..."
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
if [ -n "$interface" ]; then
	silent sudo sed -i "/.*allow-interfaces.*/c\#allow-interfaces=$interface  #commented by homebridge" /etc/avahi/avahi-daemon.conf
fi

post
