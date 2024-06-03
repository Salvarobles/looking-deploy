# Como desplegar las apps

## Estructura de carpetas

## _looking-deploy_

| looking-deploy |                                           |
| -------------- | ----------------------------------------- |
|                | [db-data](#db-data)                       |
|                | [docker-compose.yml](#docker-compose.yml) |
|                | [Dockerfile ](#Dockerfile)                |
|                | [ports.conf ](#ports.conf)                |
|                | [react-app.conf ](#react-app.conf)        |
|                | [symfony-app.conf ](#symfony-app.conf)    |

## Detalles de looking-deploy

### looking-deploy es un carpeta para desplegar nuestra aplicaciones entre ellas tenemos un docker-compose.yml, Dockerfile, ports.conf, react-app.conf y symfony-app.conf.

## db-data

**db-data** es una carpeta que almacena todos datos de nuestro servidor.

## docker-compose.yml

**docker-compose.yml** es un archivo donde se van a ejecutar nuestros contenedores, con sus respectivos puertos y variables.

```version: "2.24.6"

services:
  database:
    # Configuración para tu base de datos MariaDB
    image: mariadb
    restart: always
    container_name: database
    environment:
      MYSQL_DATABASE: lookingDB
      MARIA_ROOT_PASSWORD: salva
    ports:
      - "3306:3306"
    volumes:
      - ./db_data:/var/lib/mysql

  phpmyadmin:
    # Configuración para phpMyAdmin
    image: phpmyadmin/phpmyadmin
    ports:
      - "8080:80"
    environment:
      PMA_HOST: database
      MYSQL_ROOT_PASSWORD: salva
    depends_on:
      - database

  looking:
    build:
      context: ./
      dockerfile: Dockerfile
    container_name: looking
    ports:
      - "8000:8000"
      - "8081:80"
    volumes:
      - ./looking-backend:/var/www/html/looking-backend/
      - ./looking-frontend:/var/www/html/looking-frontend/
    environment:
      - DATABASE_URL=mysql://root:salva@database:3306/lookingDB
    depends_on:
      - database

volumes:
  db_data:
```

## Dockerfile

**Dockerfile** es un archivo en el que nos descargamos lo necesario para que nuestro contendor looking funcione.

```
# FROM php:8.3.4-fpm
FROM yiisoftware/yii2-php:8.3-apache

# Instalar extensiones y herramientas necesarias
RUN apt-get update && apt-get install -y \
    libpq-dev \
    git \
    unzip \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY symfony-app.conf /etc/apache2/sites-available/
COPY react-app.conf /etc/apache2/sites-available/
COPY ports.conf /etc/apache2/ports.conf

RUN a2dissite 000-default.conf
RUN a2ensite symfony-app.conf
RUN a2ensite react-app.conf
RUN a2enmod rewrite
RUN apt install -y nano

# Configurar directorio de trabajo
WORKDIR /var/www/html/looking-backend/


# Exponer el puerto 9000 para PHP-FPM
EXPOSE 8000
EXPOSE 80
```

## ports.conf

**ports.conf** este archivo es remplazado para el archivo _/etc/apache2/ports.conf_ para que escuche los puertos de 80 y 8000.

## react-app.conf

**react-app.conf** este archivo es para habilitar el alojamiento del frontend.

```
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html/looking-frontend/dist/

    <Directory /var/www/html/looking-frontend/dist/>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

## symfony-app.conf

**symfony-app.conf** este archivo es para habilitar el alojamiento del backend.

```
<VirtualHost *:8000>
    ServerName localhost
    DocumentRoot /var/www/html/looking-backend/public

    <Directory /var/www/html/looking-backend/public>
        AllowOverride All
        Order Allow,Deny
        Allow from All
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error-symfony.log
    CustomLog ${APACHE_LOG_DIR}/access-symfony.log combined
</VirtualHost>

```

# Desplegar en AWS

### Esta es nuestra estructura de carpetas:

| looking-deploy |                                           |
| -------------- | ----------------------------------------- |
|                | [db-data](#db-data)                       |
|                | [docker-compose.yml](#docker-compose.yml) |
|                | [Dockerfile ](#Dockerfile)                |
|                | [ports.conf ](#ports.conf)                |
|                | [react-app.conf ](#react-app.conf)        |
|                | [symfony-app.conf ](#symfony-app.conf)    |
| Nuevo          | [looking-frontend ](#looking-frontend)    |
| Nuevo          | [looking-backend ](#looking-backend)      |

## Inicar

Primero hacemos un git clone desde nuestro repositorio de github,  
`git clone https://github.com/Salvarobles/looking-deploy.git`
se nos creará la primera carpeta del documento. Pero dentro de esta tenemos que añadir los dos repositorios de frontend y backend. `git clone https://github.com/Salvarobles/looking-frontend.git` y `git clone https://github.com/Salvarobles/looking-backend.git`. Recordar **git checkout master**.

Una vez que tengamos esta estructura empezamos a instalar los recursos necesarios.

## En looking-frontend

### Instalar en la carpeta looking-frontend

```
sudo apt install nodejs npm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
```

Una vez instalados se hace un `npm install` y `npm run build`.
Se creará un carpeta _dist_.

### Configuramos el archivo .env

```
VITE_API_URL=http://{ipPublica}:8000
VITE_IMG_URL=http://{ipPublica}:8000/images/

# VITE_API_URL=http://localhost:8000
# VITE_IMG_URL=http://localhost:8000/images/
```

## En looking-backend

### Instalar en la carpeta looking-backend

Instalar php

```
# Add Ondrej's PPA
sudo add-apt-repository ppa:ondrej/php # Press enter when prompted.
sudo apt update

# Install new PHP 8.3 packages
sudo apt install php8.3 php8.3-cli php8.3-{bz2,curl,mbstring,intl}

# Install FPM OR Apache module
sudo apt install php8.3-fpm
# OR
# sudo apt install libapache2-mod-php8.2

# On Apache: Enable PHP 8.3 FPM
sudo a2enconf php8.3-fpm
# When upgrading from an older PHP version:
sudo a2disconf php8.2-fpm

## Remove old packages
sudo apt purge php8.2*
```

Instalar composer

```
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"

sudo mv composer.phar /usr/local/bin/composer
```

Una vez instalados se hace un `composer install`.

En el archivo .env

```
APP_ENV=prod
DATABASE_URL="mysql://root:salva@{ipPublica}:3306/lookingDB"
CORS_ALLOW_ORIGIN='*'
```

Crear un archivo en public que se llame .htaccess

```
<IfModule mod_rewrite.c>
    RewriteEngine On

    # Determine the RewriteBase automatically and set it as environment variable.
    RewriteCond %{REQUEST_URI}::$1 ^(/.+)/(.)::\2$
    RewriteRule ^(.) - [E=BASE:%1]

    # If the requested filename exists, simply serve it.
    # We only want to let Apache serve files and not directories.
    RewriteCond %{REQUEST_FILENAME} -f
    RewriteRule .? - [L]

    # Rewrite all other queries to the front controller.
    RewriteRule .? %{ENV:BASE}/index.php [L]
</IfModule>
```
y por ultimo seria ``docker compose build`` y ``docker compose up -d``.