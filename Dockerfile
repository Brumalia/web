ARG wintercms_version="dev-develop"
ARG php_version="7.4-apache"

FROM brumalia/base:${php_version}
LABEL maintainer="Daniel A. Hawton <daniel@hawton.org>"

COPY files/ /

RUN chown -R www-data:www-data /var/www
USER www-data
WORKDIR /var/www

# Install via composer
RUN echo "Installing ${wintercms_version}" && \
    composer create-project wintercms/winter=${winter_version} brumalia-install --no-interaction --no-scripts && \
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