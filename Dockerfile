ARG PARENT_TAG=4.4
FROM jeedom/jeedom:${PARENT_TAG}

# Maintainer
LABEL author="nicolas.richeton@gmail.com"

# Define build arguments
ARG REMOVE_MARIADB=false
ARG INSTALL_HOMEBRIDGE=true
ARG INSTALL_PLAYTTS=true
ARG INSTALL_RFLINK=true
ARG INSTALL_CAMERA=true
ARG INSTALL_FREEBOX_OS=true
ARG INSTALL_NETWORK=true
ARG INSTALL_MQTT2=true
# Z-Wave JS: installs its system dependencies (mqtt2 / Mosquitto)
ARG INSTALL_ZWAVEJS=true
# Debian bullseye only: use Freexian Extended LTS for security updates
ARG DEBIAN_ELTS=true



# Preload plugin scripts and helper script
COPY plugins /tmp/plugins
COPY install/setup.sh /root/setup.sh
COPY install/install_plugin.sh /usr/local/bin/install_plugin.sh
COPY install/debian_elts.sh /usr/local/bin/debian_elts.sh
RUN chmod +x /root/setup.sh /usr/local/bin/install_plugin.sh /usr/local/bin/debian_elts.sh

# Fix APT sources of end-of-life Debian releases (bullseye), no-op otherwise
RUN DEBIAN_ELTS="$DEBIAN_ELTS" debian_elts.sh

# Conditionally remove MariaDB
RUN if [ "$REMOVE_MARIADB" = "true" ]; then \
        apt-get remove -y mariadb-client mariadb-common mariadb-server; \
        # configure setup.sh / set REMOVE_MARIADB=true
        sed -i 's/.*REMOVE_MARIADB=false.*/REMOVE_MARIADB=true/' /root/setup.sh; \
    fi

# Base dependencies
RUN export DEBIAN_FRONTEND=noninteractive && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && apt-get -y dist-upgrade && apt-get -y autoremove && \
    apt-get install --no-install-recommends -y default-mysql-client git dumb-init

# Install Homebridge
RUN if [ "$INSTALL_HOMEBRIDGE" = "true" ]; then \
        install_plugin.sh homebridge; \
    fi

# Install PlayTTS
RUN if [ "$INSTALL_PLAYTTS" = "true" ]; then \
        install_plugin.sh playtts; \
    fi

# Install RFLink
RUN if [ "$INSTALL_RFLINK" = "true" ]; then \
        install_plugin.sh rflink; \
         # configure setup.sh / set INSTALL_RFLINK=true
         sed -i 's/.*INSTALL_RFLINK=false.*/INSTALL_RFLINK=true/' /root/setup.sh; \
    fi

# Install Camera
RUN if [ "$INSTALL_CAMERA" = "true" ]; then \
        install_plugin.sh camera; \
    fi

# Install Freebox OS
RUN if [ "$INSTALL_FREEBOX_OS" = "true" ]; then \
        install_plugin.sh freebox_os; \
    fi

# Install Network
RUN if [ "$INSTALL_NETWORK" = "true" ]; then \
        install_plugin.sh network; \
    fi

# Install MQTT Manager (mqtt2), also required by Z-Wave JS
RUN if [ "$INSTALL_MQTT2" = "true" ] || [ "$INSTALL_ZWAVEJS" = "true" ]; then \
        install_plugin.sh mqtt2; \
    fi

# Reduce image size
RUN apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clean up /tmp: plugin installers (playtts, ...) clone/extract
# directly into /tmp and are not removed by install_plugin.sh. A leftover
# /tmp full of files makes the base image's startup chmod on /tmp very slow.
RUN rm -rf /tmp/* /tmp/.[!.]*

# Setup script
RUN sed -i 's/.*service atd restart.*/service atd restart.\n\/root\/setup.sh/' /root/init.sh

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["bash", "/root/init.sh"]
