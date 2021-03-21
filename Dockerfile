FROM php:7.4-apache
LABEL maintainer="Daniel A. Hawton <daniel@hawton.org>"

ARG wintercms_version="dev-develop"

RUN a2enmod expires rewrite

# Install CMS dependencies
RUN apt update && apt install -y --no-install-recommends \
    unzip libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev libyaml-dev libzip4 \
    libzip-dev zlib1g-dev libicu-dev libpq-dev libsqlite3-dev g++ git cron nano ssh-client && \
    docker-php-ext-install opcache && \
    docker-php-ext-configure intl && \
    docker-php-ext-install intl && \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install -j$(nproc) gd && \
    docker-php-ext-install exif && \
    docker-php-ext-install zip && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-install pdo_pgsql && \
    rm -rf /var/lib/apt/lists/*

# Install apcu and yaml
RUN pecl install apcu && \
    pecl install yaml && \
    docker-php-ext-enable apcu yaml

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY files/ /

RUN chown -R www-data:www-data /var/www
USER www-data
WORKDIR /var/www

# Install via composer
RUN composer create-project wintercms/winter brumalia-install "${wintercms_version}" --no-interaction --no-scripts && \
    mv -T /var/www/brumalia-install /var/www/html

WORKDIR /var/www/html

# Run some commands, set a default key that *should* be changed by users post-install to have it unique
# Key will be in config until https://github.com/wintercms/winter/issues/29 is resolved rather than in .env
RUN php artisan winter:env && \
    php artisan key:generate && \
    php artisan package:discover

# Setup crontab
RUN (crontab -l; echo "* * * * * cd /var/www/html && /usr/local/bin/php artisan schedule:run 1>> /dev/null 2>&1") | crontab -

USER root

RUN chmod +x /entrypoint.sh

VOLUME ["/var/www/html"]
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["sh","-c", "cron && apache2-foreground"]