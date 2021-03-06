if [ ! -z ${APACHE_PORT} ]; then
	echo 'Change apache listen port to: '${APACHE_PORT}
	echo "Listen ${APACHE_PORT}" > /etc/apache2/ports.conf
	sed -i -E "s/\<VirtualHost \*:(.*)\>/VirtualHost \*:${APACHE_PORT}/" /etc/apache2/sites-enabled/000-default.conf
else
	echo "Listen 80" > /etc/apache2/ports.conf
	sed -i -E "s/\<VirtualHost \*:(.*)\>/VirtualHost \*:80/" /etc/apache2/sites-enabled/000-default.conf
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