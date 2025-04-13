# jeedom-optimized - Image Docker Jeedom avec dépendances pré-installées

## Présentation 

Cette image "nricheton/jeedom-optimized" est basée sur l'image originale "jeedom/jeedom" en installant certaines dépendances de plugins : 

  - Zwave
  - Networks
  - Homebridge
  - Camera
  - FreeboxOS
  - RFLink

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
  
  - **nricheton/jeedom-optimized:latest** : basé sur jeedom/jeedom:latest. En cas de nouvelle installation, installe Jeedom v4 
  - **nricheton/jeedom-optimized:3-latest** : basé sur jeedom/jeedom:latest. En cas de nouvelle installation, installe Jeedom v3
  - **nricheton/jeedom-optimized:rpi-latest** : inspiré de jeedom/jeedom:latest mais image pour architecture ARM/Raspberry Pi. En cas de nouvelle installation, installe Jeedom v4

## Configuration supplémentaires 

En plus des variables d'environnement de l'image jeedom:latest, cette image peut utiliser les variables suivantes : 

- APACHE_PORT=<port> : Permet de régler le port du server apache lors d'une utilisation en mode host networking. Cette option a disparu de l'image Jeedom officielle. 
- SOUND_CARD=<numero> : Permet de régler la carte son par défaut, si vous utilisez une carte son USB par exemple
- HOSTNAME=<nom> : Permet de configurer le hostname, lors d'une utilisation en mode host networking

*Attention*, si vous retirez MariaDB de l'image, utiliser les variables d'environnement standard pour initialiser une base externe :
- DB_HOST=jeedom_db
- DB_USERNAME=jeedom
- DB_PASSWORD=TODO
- DB_NAME=jeedom

 Voir https://doc.jeedom.com/fr_FR/installation/docker pour les instructions officielles


## Utilisation 
  
Jeedom utilise 2 conteneurs : un pour la base de données et l'autre pour Jeedom.

### Conteneur Mysql 

```
docker run --name jeedom-mysql -v jeedom-mysql:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=password-root-sql \
  -e MYSQL_USER=jeedom -e MYSQL_PASSWORD=password-jeedom-sql -e MYSQL_DATABASE=jeedom --detach --publish 3306:3306 \
  --restart unless-stopped mariadb:10.4
```

### Conteneur Jeedom
```
docker run --name jeedom-server --restart unless-stopped --net host --volume jeedom-html:/var/www/html \
  --env APACHE_PORT="9080" --env ROOT_PASSWORD="password-admin-jeedom" \
  --device  "/dev/ttyACM1:/dev/ttyUSB0" --detach nricheton/jeedom-optimized:latest 
```

### Installation de Jeedom

Au premier lancement, Jeedom va demander les informations de la base de données.

- **Database hostname** : Le nom/IP de votre serveur Docker, c'est-à-dire celui où vous avez démarré le conteneur `jeedom-mysql`. Ne peut pas être `localhost` ou `127.0.0.1` car vous devez vous connecter en dehors du conteneur Jeedom.
- **Database port** : Port publié de `jeedom-mysql`. Par défaut : `3306`.
- **Database username** : `jeedom` (ou ce que vous avez indiqué à la création de `jeedom-mysql`).
- **Database password** : `password-jeedom-sql` (vous avez dû changer le mot de passe à la création de `jeedom-mysql`).
- **Database name** : `jeedom` (ou ce que vous avez indiqué à la création de `jeedom-mysql`).

---

### Notes

- Il est nécessaire de faire fonctionner Jeedom avec un réseau en mode `host` pour utiliser Homebridge / Maison sur iOS & macOS. Le protocole Bonjour nécessite de pouvoir envoyer des messages sur le réseau en broadcast.
- En mode `host`, on ne peut pas lier des conteneurs. Jeedom doit donc accéder à la base de données en utilisant l'IP du host Docker et le port publié par le conteneur MySQL.

---

### Migration depuis un Jeedom existant

- Exporter la base MySQL (`fichier.sql`). Jeedom fait des backups automatiques, vous pouvez repartir de ceux-ci.
- Copier le contenu du dossier `/var/www` (fichiers et configuration de Jeedom).

- Restaurer la base sur le conteneur `jeedom-mysql`. Via Docker :
```bash
docker exec -it jeedom-mysql bash
mysql -u jeedom -p jeedom < backup.sql 
```
Ou via un client SQL.

- Restaurer le dossier `/var/www` dans le volume `jeedom-html`.
- Ajuster le fichier de configuration de Jeedom pour pointer sur la nouvelle base.

---

### Documentation complémentaire

Cette image est totalement compatible avec l'image officielle Jeedom. Vous trouverez des compléments et tutoriels dans la [documentation officielle d'installation](https://jeedom.github.io/documentation/installation/fr_FR/index).

## Modules et arguments de build

Lors de la construction de l'image Docker, vous pouvez sélectionner les modules à installer en utilisant des arguments de build. Cela permet de personnaliser l'image en fonction de vos besoins spécifiques. Les modules disponibles sont les suivants :

- **Homebridge** : Permet l'intégration avec l'application Maison d'Apple.
- **PlayTTS** : Ajoute la synthèse vocale pour les notifications.
- **RFLink** : Supporte les périphériques RFLink.
- **Camera** : Ajoute le support pour les caméras via `ffmpeg` et `php-gd`.
- **Freebox OS** : Ajoute le support pour Freebox OS avec `android-tools-adb` et `netcat-traditional`.
- **Z-Wave** : Installe les dépendances pour le plugin Z-Wave.

### Arguments disponibles

- `INSTALL_HOMEBRIDGE` : Installe le module Homebridge (valeurs possibles : `true` ou `false`).
- `INSTALL_PLAYTTS` : Installe le module PlayTTS (valeurs possibles : `true` ou `false`).
- `INSTALL_RFLINK` : Installe le module RFLink (valeurs possibles : `true` ou `false`).
- `INSTALL_CAMERA` : Installe le module Camera (valeurs possibles : `true` ou `false`).
- `INSTALL_FREEBOX_OS` : Installe le module Freebox OS (valeurs possibles : `true` ou `false`).
- `INSTALL_OPENZWAVE` : Installe les dépendances pour le plugin open Z-Wave (valeurs possibles : `true` ou `false`).
- `INSTALL_NETWORK` : Installe les outils réseau (valeurs possibles : `true` ou `false`).
- `REMOVE_MARIADB` : Supprime MariaDB du conteneur (valeurs possibles : `true` ou `false`).

### Exemple de commande de build

Pour construire une image avec Homebridge, RFLink et Camera, mais sans PlayTTS, Freebox OS, Z-Wave, et en supprimant MariaDB, utilisez la commande suivante :

```bash
docker build \
  --build-arg INSTALL_HOMEBRIDGE=true \
  --build-arg INSTALL_PLAYTTS=true \
  --build-arg INSTALL_RFLINK=false \
  --build-arg INSTALL_CAMERA=true \
  --build-arg INSTALL_FREEBOX_OS=false \
  --build-arg INSTALL_OPENZWAVE=true \
  --build-arg INSTALL_NETWORK=true \
  --build-arg REMOVE_MARIADB=true \
  -t jeedom-custom .
```

En omettant un argument, sa valeur par défaut sera `true` pour les plugins, et `false` pour le retrait de MariaDB.