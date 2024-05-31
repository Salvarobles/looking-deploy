# FROM php:8.3.4-fpm
FROM yiisoftware/yii2-php:8.1-apache

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
RUN apt install -y nano

# Configurar directorio de trabajo
WORKDIR /var/www/html/looking-backend/

# Instalar las dependencias de Composer
# RUN composer install

# Exponer el puerto 9000 para PHP-FPM
EXPOSE 8000
EXPOSE 80
