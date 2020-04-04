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
  
### Conteneur Mysql 

```
docker run --name jeedom-mysql -v jeedom-mysql:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=password-root-sql \
  -e MYSQL_USER=jeedom -e MYSQL_PASSWORD=password-jeedom-sql -e MYSQL_DATABASE jeedom --detach --publish 3306:3306 \
  --restart unless-stopped mariadb:10.4
```

### Conteneur Jeedom
```
docker run --name jeedom-server --restart unless-stopped --net host --volume jeedom-html:/var/www/html \
  --env APACHE_PORT="9080" --env  SSH_PORT="9022" --env MODE_HOST="1" --env ROOT_PASSWORD="password-admin-jeedom" \
  --device  "/dev/ttyACM1:/dev/ttyUSB0" --detach nricheton/jeedom-optimized:latest 
```

Notes: 
  - Il est nécessaire de faire fonctionner jeedom avec un réseau en mode 'host' pour utiliser Homebridge / Maison sur iOS & MacOS. Le protocole Bonjour nécessite de pouvoir envoyer des messages sur le réseau en broadcast.
  - En mode host, on ne peut pas lier des conteneurs. Jeedom doit donc accéder à la base de données en utiliser l'IP du host docker et le port publié par le conteneur mysql.

### Installation de Jeedom

Au premier lancement, jeedom va demander les nformations de la base de données. 

- Database hostname : Le nom/IP de votre serveur docker. Celio ou vous avez démarré le conteneur jeedom-mysql. Ne peut pas être 'localhost' or 127.0.0.1 car vous devez vous connecter en dehors du conteneur jeedom.
- Database port : Port publié de jeedom-mysql. Par défaut : 3306
- Database username : jeedom (ou ce que vous avez indiqué à la création de jeedom-mysql)
- Database password : password-jeedom-sql (vous avez dû changer le mot de passe à la création de jeedom-mysql)
- database name : jeedom (ou ce que vous avez indiqué à la création de jeedom-mysql)


## Migration depuis un jeedom existant : 

- Exporter la base mysql (fichier.sql). Jeedom fait des backups automatiques, nous pouvez repartir de ceux-ci
- Copier le contenu du dossier /var/www. (Fichiers et conf de jeedom)

- Restorer la base sur le conteneur jeedom-mysql
```
docker exec -it jeedom-mysql bash
mysql -u jeedom -p jeedom < backup.sql 
```

- Restorer le dossier www dans le volume jeedom-html 
- Ajuster le fichier de configuration de jeedom pour taper sur la nouvelle base.
