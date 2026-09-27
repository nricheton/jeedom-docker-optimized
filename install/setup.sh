#!/bin/bash

echo "Setup at launch time (nricheton/jeedom-optimized)"

if [ ! -z ${APACHE_PORT} ]; then
	echo 'Change apache listen port to: '${APACHE_PORT}
	echo "Listen ${APACHE_PORT}" > /etc/apache2/ports.conf
	sed -i -E "s/\<VirtualHost \*:(.*)\>/VirtualHost \*:${APACHE_PORT}/" /etc/apache2/sites-enabled/000-default.conf
#else
#	echo "Listen 80" > /etc/apache2/ports.conf
#	sed -i -E "s/\<VirtualHost \*:(.*)\>/VirtualHost \*:80/" /etc/apache2/sites-enabled/000-default.conf
fi



if [ ! -z ${SOUND_CARD} ]; then
	echo 'Setup soundcard to: '${SOUND_CARD}
    echo "defaults.pcm.card ${SOUND_CARD}" > /etc/asound.conf
    echo "defaults.ctl.card ${SOUND_CARD}"  >> /etc/asound.conf
    amixer sset 'Speaker' 100%
fi


if [ ! -z ${HOSTNAME} ]; then
	echo 'Setup hostname to: '${HOSTNAME}
	echo "${HOSTNAME}" > /etc/hostname 
    echo "127.0.0.1 ${HOSTNAME}" >> /etc/hosts
    echo ":1 ${HOSTNAME}" >> /etc/hosts
fi

REMOVE_MARIADB=false
# Remove mariadb in case some plugin adds it 
if [ ${REMOVE_MARIADB} = true ]; then
  echo "Remove mariadb"
  apt-get remove -y mariadb-client mariadb-common mariadb-server
fi

# npm runs as www-data (HOME=/var/www) in plugin installers and daemons, but
# /var/www is root:root 775, so www-data cannot create its cache there. Root
# (or sudo) npm runs can also leave root-owned files in it (EACCES).
mkdir -p /var/www/.npm
chown -R www-data:www-data /var/www/.npm

# Mosquitto (mqtt2 "local" mode): the plugin's init script writes its pidfile
# to /run/mosquitto, which is normally created by systemd (absent in Docker).
if [ -x /usr/sbin/mosquitto ]; then
	mkdir -p /run/mosquitto
	chown mosquitto:mosquitto /run/mosquitto
fi

# RFLink serialport fix (installed only when the image includes RFLink).
# Jeedom starts the daemon itself later, so don't restart it here.
if [ -x /usr/local/bin/rflink_fix.sh ]; then
	/usr/local/bin/rflink_fix.sh --no-restart
fi

# Ignore error from previous command
echo "Setup at launch time : done"
