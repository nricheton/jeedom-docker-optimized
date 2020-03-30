# jeedom-docker-optimized - Image Docker Jeedom avec dépendances pré-installées

## Présentation 

Cette image "nricheton/jeedom-optimized" est basée sur l'image originale "jeedom/jeedom" en installant certaines dépendances de plugins : 

  - Zwave
  - Networks
  - Homebridge

Cela permet d'avoir un jeedom *immédiatement opérationnel* lorsque le container est recréé, sans avoir à lancer l'installation des dépendances de chaque plugins. 

## Jeedom

Jeedom permet de nombreuses possibilités dont :

  - Gérer la sécurité des biens et des personnes,
  - Automatiser le chauffage pour un meilleur confort et des économies d'énergie,
  - Visualiser et gérer la consommation énergétique, pour anticiper une dépense et réduire les consommations,
  - Communiquer par la voix, des SMS, des mails ou des applications mobiles,
  - Gérer tous les automatismes de la maison, volets, portail, lumières...
  - Gérer ses périphériques multimédia audio et vidéo, et ses objets connectés.
  
## Tags 
  
  - latest : basé sur jeedom/jeedom:latest. En cas de nouvelle installation, installe jeedom v4 
  - 3-latest : basé sur jeedom/jeedom:latest. En cas de nouvelle installation, installe jeedom v3
  - rpi-latest : inspiré de jeedom/jeedom:latest mais image pour architecture arm/Raspberry pi. En cas de nouvelle installation, installe jeedom v4 (Non opérationnel)

## Utilisation 
  
### Mysql 

```
docker run --name jeedom-mysql -v jeedom-mysql:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=password-root-sql \
  -e MYSQL_USER=jeedom -e MYSQL_PASSWORD=password-jeedom-sql --detach --publish 3306:3306 \
  --restart unless-stopped mariadb:10.4
```

### Jeedom
```
docker run --name jeedom-server --restart unless-stopped --net host --volume jeedom-html:/var/www/html \
  --env APACHE_PORT="9080" --env  SSH_PORT="9022" --env MODE_HOST="1" --env ROOT_PASSWORD="password-admin-jeedom" \
  --device  "/dev/ttyACM1:/dev/ttyUSB0" --detach nricheton/jeedom-optimized:latest 
```
