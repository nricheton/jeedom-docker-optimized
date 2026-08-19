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

INSTALL_RFLINK=false
if [ ${INSTALL_RFLINK} = true ]; then
	cd /var/www/html/plugins/rflink/resources

	# The rflink plugin may declare an old serialport version that doesn't
	# work with recent node versions. Bump it in package.json before
	# installing, but never downgrade a version the plugin already declares.
	MIN_SERIALPORT_VERSION="13.0.5"
	MIN_BINDINGS_CPP_VERSION="12.0.0"
	CURRENT_SERIALPORT_VERSION=$(node -p "require('./package.json').dependencies.serialport" 2>/dev/null | sed -E 's/^[^0-9]*//')
	if [ -n "${CURRENT_SERIALPORT_VERSION}" ]; then
		OLDEST=$(printf '%s\n' "${MIN_SERIALPORT_VERSION}" "${CURRENT_SERIALPORT_VERSION}" | sort -V | head -n1)
		if [ "${OLDEST}" = "${CURRENT_SERIALPORT_VERSION}" ] && [ "${CURRENT_SERIALPORT_VERSION}" != "${MIN_SERIALPORT_VERSION}" ]; then
			echo "rflink: declared serialport ${CURRENT_SERIALPORT_VERSION} is older than ${MIN_SERIALPORT_VERSION}, bumping"
			npm pkg set "dependencies.serialport=${MIN_SERIALPORT_VERSION}" "dependencies.@serialport/bindings-cpp=${MIN_BINDINGS_CPP_VERSION}"
		fi
	fi

	# Ensure RF link works with a recent node version
	npm rebuild && npm install && chown -R www-data node_modules
fi

# Ignore error from previous command
echo "Setup at launch time : done"
