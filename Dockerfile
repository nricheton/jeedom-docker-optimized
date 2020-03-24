FROM jeedom/jeedom:latest

MAINTAINER nicolas.richeton@gmail.com

## Preinstall dependencies
RUN apt-get update && apt-get -y dist-upgrade 

# Mysql client
RUN apt-get install --no-install-recommends -y default-mysql-client

# Plugin Network : fix ping
RUN apt-get install --no-install-recommends -y iputils-ping

# Plugin Z wave
RUN apt-get install --no-install-recommends -y git python-pip python-dev python-pyudev python-setuptools python-louie \
    make build-essential libudev-dev g++ gcc python-lxml unzip libjpeg-dev python-serial python-requests
RUN pip install wheel urwid louie six tornado

# Plugin Homebridge
RUN echo "\
Package: nodejs \n\
Pin: origin deb.nodesource.com \n\
Pin-Priority: 600 \n" >> /etc/apt/preferences.d/nodesource

RUN apt-get install --no-install-recommends -y build-essential avahi-daemon lsb-release avahi-discover avahi-utils \
    libnss-mdns libavahi-compat-libdnssd-dev dialog apt-utils curl
    
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install --no-install-recommends -y nodejs  

RUN  npm install -g npm  


## Reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
