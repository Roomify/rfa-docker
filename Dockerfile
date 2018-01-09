FROM php:7.0-apache

# Find the latest release tag here: https://github.com/Roomify/RfA/releases/latest
ENV RFA_VERSION=1.5.1

RUN a2enmod rewrite

RUN apt-get update && apt-get -y install git mysql-client vim-tiny wget

# install the PHP extensions we need
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev libpq-dev zlib1g-dev zip netcat-openbsd \
&& rm -rf /var/lib/apt/lists/* \
&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
&&  docker-php-ext-install gd mbstring pdo pdo_mysql pdo_pgsql zip

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Install Drush 8.
RUN composer global require drush/drush:8.*
RUN composer global update
RUN ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

# Add drush comand https://www.drupal.org/project/registry_rebuild
RUN wget http://ftp.drupal.org/files/projects/registry_rebuild-7.x-2.2.tar.gz && \
    tar xzf registry_rebuild-7.x-2.2.tar.gz && \
    rm registry_rebuild-7.x-2.2.tar.gz && \
    mv registry_rebuild /root/.composer/vendor/drush/drush/commands

# Copy over PHP config files
COPY config/php.ini /usr/local/etc/php/

WORKDIR /var/www/html

# Download RfA.
RUN curl -fSL "https://github.com/Roomify/RfA/releases/download/${RFA_VERSION}/roomify-accommodations-default.${RFA_VERSION}.zip" -o rfa.zip \
  && unzip rfa.zip \
  && rm rfa.zip \
  && find roomify-accommodations/ -mindepth 1 -maxdepth 1 -exec mv -t . -- {} + \
  && rmdir roomify-accommodations \
  && chown -R www-data:www-data sites

COPY entrypoint.sh /entrypoint.sh
COPY default.settings.php sites/default/settings.php
RUN chmod 755 /*.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
