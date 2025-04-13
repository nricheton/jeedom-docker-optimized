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
    echo "defaults.pcm.card ${SOUND_CARD}\ndefaults.ctl.card ${SOUND_CARD}" > /etc/asound.conf
    
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

INSTALL_RFLINK=false
if [ ${INSTALL_RFLINK} = true ]; then
	# Ensure RF link works with a recent node version
	cd /var/www/html/plugins/rflink/resources && npm rebuild && npm install && chown -R www-data node_modules
fi

# Ignore error from previous command
echo "Setup at launch time : done"
