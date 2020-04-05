#!/bin/bash
######################### INCLUSION LIB ##########################
BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
wget https://raw.githubusercontent.com/NebzHB/dependance.lib/master/dependance.lib -O $BASEDIR/dependance.lib &>/dev/null
PLUGIN=$(basename "$(realpath $BASEDIR/..)")
. ${BASEDIR}/dependance.lib
##################################################################

installVer='12' 	#NodeJS major version to be installed
minVer='12'	#min NodeJS major version to be accepted
maxVer='12'

pre
step 0 "Vérification des droits"
DIRECTORY="/var/www"
if [ ! -d "$DIRECTORY" ]; then
	silent sudo mkdir $DIRECTORY
fi
silent sudo chown -R www-data $DIRECTORY

step 10 "Prérequis"
silent sudo killall homebridge
if [ -f /etc/apt/sources.list.d/deb-multimedia.list* ]; then
  echo "Vérification si la source deb-multimedia existe (bug lors du apt-get update si c'est le cas)"
  echo "deb-multimedia existe !"
  if [ -f /etc/apt/sources.list.d/deb-multimedia.list.disabledByHomebridge ]; then
    echo "mais on l'a déjà désactivé..."
  else
    if [ -f /etc/apt/sources.list.d/deb-multimedia.list ]; then
      echo "Désactivation de la source deb-multimedia !"
      silent sudo mv /etc/apt/sources.list.d/deb-multimedia.list /etc/apt/sources.list.d/deb-multimedia.list.disabledByHomebridge
    else
      if [ -f /etc/apt/sources.list.d/deb-multimedia.list.disabled ]; then
        echo "mais il est déjà désactivé..."
      else
        echo "mais n'est ni 'disabled' ou 'disabledByHomebridge'... il sera normalement ignoré donc ca devrait passer..."
      fi
    fi
  fi
fi

toReAddRepo=0
if [ -f /media/boot/multiboot/meson64_odroidc2.dtb.linux ]; then
    hasRepo=$(grep "repo.jeedom.com" /etc/apt/sources.list | wc -l)
    if [ "$hasRepo" -ne "0" ]; then
      echo "Désactivation de la source repo.jeedom.com !"
      toReAddRepo=1
      silent sudo apt-add-repository -r "deb http://repo.jeedom.com/odroid/ stable main"
    fi
fi

#prioritize nodesource nodejs
try sudo bash -c "cat >> /etc/apt/preferences.d/nodesource" << EOL
Package: nodejs
Pin: origin deb.nodesource.com
Pin-Priority: 600
EOL

step 20 "Mise à jour APT et installation des packages nécessaires"
try sudo apt-get update
try sudo DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential avahi-daemon lsb-release avahi-discover avahi-utils libnss-mdns libavahi-compat-libdnssd-dev dialog apt-utils

step 30 "Vérification de la version de NodeJS installée"
silent type nodejs
if [ $? -eq 0 ]; then actual=`nodejs -v`; fi
echo "Version actuelle : ${actual}"
arch=`arch`;

#jeedom mini and rpi 1 2, 12 does not support arm6l
if [[ $arch == "armv6l" ]]
then
  installVer='8' 	#NodeJS major version to be installed
  minVer='8'	#min NodeJS major version to be accepted  
fi

#jessie as libstdc++ > 4.9 needed for nodejs 12
lsb_release -c | grep jessie
if [ $? -eq 0 ]
then
  installVer='8' 	#NodeJS major version to be installed
  minVer='8'	#min NodeJS major version to be accepted  
fi

bits=$(getconf LONG_BIT)
vers=$(lsb_release -c | grep stretch | wc -l)
if { [ "$arch" = "i386" ] || [ "$arch" = "i686" ]; } && [ "$bits" -eq "32" ] && [ "$vers" -eq "1" ]
then 
  installVer='8' 	#NodeJS major version to be installed
  minVer='8'	#min NodeJS major version to be accepted  
fi

testVer=$(php -r "echo version_compare('${actual}','v${minVer}','>=');")
if [[ $testVer == "1" ]]
then
  echo "Ok, version suffisante";
  new=$actual
else
  step 40 "Installation de NodeJS $installVer"
  echo "KO, version obsolète à upgrader";
  echo "Suppression du Nodejs existant et installation du paquet recommandé"
  #if npm exists
  silent type npm
  if [ $? -eq 0 ]; then
    silent sudo npm rm -g homebridge-alexa
    silent sudo npm rm -g homebridge-camera-ffmpeg
    silent sudo npm rm -g homebridge-jeedom
    silent sudo npm rm -g homebridge
    silent sudo npm rm -g request
    silent sudo npm rm -g node-gyp
    cd `npm root -g`;
    silent sudo npm rebuild
    npmPrefix=`npm prefix -g`
  else
    npmPrefix="/usr"
  fi
  
  silent sudo DEBIAN_FRONTEND=noninteractive apt-get -y --purge autoremove npm
  silent sudo DEBIAN_FRONTEND=noninteractive apt-get -y --purge autoremove nodejs
  
  echo 45 > ${PROGRESS_FILE}
  echo "--45%"
  if [[ $arch == "armv6l" ]]
  then
    echo "Raspberry 1, 2 ou zéro détecté, utilisation du paquet v${installVer} pour ${arch}"
    try wget -nd -nH -nc -np -e robots=off -r -l1 --no-parent -A"node-*-linux-${arch}.tar.gz" https://nodejs.org/download/release/latest-v${installVer}.x/
    try tar -xvf node-*-linux-${arch}.tar.gz
    try cd node-*-linux-${arch}
    try sudo cp -R * /usr/local/
    try cd ..
    silent rm -fR node-*-linux-${arch}*
    silent ln -s /usr/local/bin/node /usr/bin/node
    silent ln -s /usr/local/bin/node /usr/bin/nodejs
    #upgrade to recent npm
    try sudo npm install -g npm
  else
    echo "Utilisation du dépot officiel"
    try curl -sL https://deb.nodesource.com/setup_${installVer}.x | sudo -E bash -
    try sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs  
  fi
  
  silent npm config set prefix ${npmPrefix}

  new=`nodejs -v`;
  echo "Version actuelle : ${new}"
fi

silent type npm
if [ $? -ne 0 ]; then
  step 45 "Installation de npm car non présent"
  try sudo DEBIAN_FRONTEND=noninteractive apt-get install -y npm  
  try sudo npm install -g npm
fi

step 50 "Nettoyage anciens modules"
silent sudo npm ls -g homebridge-alexa
if [ $? -ne 1 ]; then
  echo "Suppression homebridge-alexa global"
  silent sudo npm rm -g homebridge-alexa
fi
silent sudo npm ls -g homebridge
if [ $? -ne 1 ]; then
  echo "Suppression homebridge global"
  silent sudo rm -f /usr/bin/homebridge
  silent sudo rm -f /usr/local/bin/homebridge
  silent sudo npm rm -g homebridge-camera-ffmpeg
  silent sudo npm rm -g homebridge-jeedom
  silent sudo npm rm -g homebridge
  silent sudo npm rm -g request
  silent sudo npm rm -g node-gyp
  silent cd `npm root -g`;
  silent sudo npm rebuild
fi
cd ${BASEDIR};
#remove old local modules
silent sudo rm -rf node_modules
silent sudo rm -f package-lock.json

if [ -n $2 ]; then
	BRANCH=$2
else
	BRANCH="master"
fi
step 60 "Installation de Homebridge ${BRANCH}, veuillez patienter svp"
silent sudo sed -i "/.*homebridge-jeedom.*/c\    \"homebridge-jeedom\": \"NebzHB/homebridge-jeedom#${BRANCH}\"," ./package.json
#need to be sudoed because of recompil
silent sudo mkdir node_modules
silent sudo chown -R www-data:www-data .
try sudo npm install --no-fund --no-package-lock --no-audit
silent sudo chown -R www-data:www-data .
#authorize www-data to use the video device (/dev/vchiq on RPI or video accelerator)
silent sudo usermod -aG video www-data


testGMP=$(php -r "echo extension_loaded('gmp');")
silent sudo service php5-fpm status
nginxPresent=$?
if [[ "$testGMP" != "1" ]]; then
  if [[ "$nginxPresent" != "0" ]]; then
    step 70 "Installation de l'extension gmp pour le QRCode"
    silent sudo DEBIAN_FRONTEND=noninteractive apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y php-gmp
  
    silent sudo service apache2 status
    if [ $? = 0 ]; then
      echo "Reload apache2..."
      silent sudo systemctl daemon-reload
      silent sudo systemctl reload apache2.service || silent sudo service apache2 reload
    fi
  fi
fi

step 80 "Configuration Avahi"
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

step 90 "Nettoyage 1/2"
# removing old node solution
if [ -e ${BASEDIR}/../node ]; then
  silent cd ${BASEDIR}/../node/
  silent sudo npm cache verify
  silent cd ${BASEDIR}/../
  silent sudo rm -Rf ${BASEDIR}/../node
fi
# cleaning of past tries
if [[ `file -bi /usr/bin/ffmpeg` == *"text/x-shellscript"* ]]; then 
  silent sudo rm -f /usr/bin/ffmpeg
fi 

step 95 "Nettoyage 2/2"
silent sudo rm -f /etc/apt/preferences.d/nodesource
if [ -f /etc/apt/sources.list.d/deb-multimedia.list.disabledByHomebridge ]; then
  echo "Réactivation de la source deb-multimedia qu'on avait désactivé !"
  silent sudo mv /etc/apt/sources.list.d/deb-multimedia.list.disabledByHomebridge /etc/apt/sources.list.d/deb-multimedia.list
fi
if [ "$toReAddRepo" -ne "0" ]; then
  echo "Réactivation de la source repo.jeedom.com qu'on avait désactivé !"
  toReAddRepo=0
  silent sudo apt-add-repository "deb http://repo.jeedom.com/odroid/ stable main"
fi

post

