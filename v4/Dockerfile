FROM jeedom/jeedom:latest

MAINTAINER nicolas.richeton@gmail.com

# Preload homebridge install script
ADD ../plugins/homebridge/install_homebridge.sh /tmp/install_homebridge.sh

## Preinstall dependencies
RUN apt-get update && apt-get -y dist-upgrade && \
# Mysql client & git
    apt-get install --no-install-recommends -y default-mysql-client git && \
# Plugin Network : fix ping
    apt-get install --no-install-recommends -y iputils-ping && \
# Plugin Z wave
    mkdir -p /tmp/jeedom/openzwave/ && cd /tmp && \
    git clone https://github.com/jeedom/plugin-openzwave.git && cd plugin-openzwave && git checkout master && cd resources && \
    chmod u+x ./install_apt.sh && ./install_apt.sh && cd /tmp && rm -Rf plugin-openzwave \
# Plugin Homebridge
    cd tmp && chmod u+x ./install_homebridge.sh && ./install_homebridge.sh \
#   echo "\
#Package: nodejs \n\
#Pin: origin deb.nodesource.com \n\
#Pin-Priority: 600 \n" >> /etc/apt/preferences.d/nodesource && \
#    apt-get install --no-install-recommends -y build-essential avahi-daemon lsb-release avahi-discover avahi-utils \
#    libnss-mdns libavahi-compat-libdnssd-dev dialog apt-utils curl && \
#    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
#    apt-get install --no-install-recommends -y nodejs && \
#    npm install -g npm && \
# Reduce image size
    apt-get clean && rm -rf /var/lib/apt/lists/*
