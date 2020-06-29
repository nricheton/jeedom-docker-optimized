if [ ! -z ${APACHE_PORT} ]; then
	echo 'Change apache listen port to : '${APACHE_PORT}
	echo "Listen ${APACHE_PORT}" > /etc/apache2/ports.conf
	sed -i -E "s/\<VirtualHost \*:(.*)\>/VirtualHost \*:${APACHE_PORT}/" /etc/apache2/sites-enabled/000-default.conf
else
	echo "Listen 80" > /etc/apache2/ports.conf
	sed -i -E "s/\<VirtualHost \*:(.*)\>/VirtualHost \*:80/" /etc/apache2/sites-enabled/000-default.conf
fi
