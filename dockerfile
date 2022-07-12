# FROM php:8.0-fpm

# # # Configure & Install Extension
# # RUN docker-php-ext-configure \
# #     opcache --enable-opcache &&\
# #     docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/ && \
# #     docker-php-ext-install \
# #     opcache \
# #     mysqli \
# #     mbstring \
# #     mcrypt \
# #     memcached \
# #     exif \
# #     pdo \
# #     pdo_mysql \
# #     sockets \
# #     json \
# #     intl \
# #     gd \
# #     xml \
# #     bz2 \
# #     pcntl \
# #     bcmath \
# #     zip

# # Add docker php ext repo
# ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# # Install php extensions
# RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
#     install-php-extensions mbstring pdo_mysql zip exif pcntl gd memcached

# # # Add Build Dependencies
# # RUN apt update -y && apt install -y \
# #     libpng-dev \
# #     libxml2-dev \
# #     zip \
# #     unzip \
# #     git \
# #     curl \
# #     lua-zlib-dev \
# #     libmemcached-dev 

# # # Add Production Dependencies
# # RUN apt install -y \
# #     jpegoptim \
# #     pngquant \
# #     optipng \
# #     supervisor \
# #     nano \
# #     icu-dev \
# #     freetype-dev \
# #     nginx \
# #     mysql-client \
# #     libzip-dev

# # Install dependencies
# RUN apt update -y && apt install -y default-mysql-server default-mysql-client default-libmysqlclient-dev
# RUN apt update -y && apt install -y \
#     build-essential \
#     libpng-dev \
#     libjpeg62-turbo-dev \
#     libfreetype6-dev \
#     locales \
#     zip \
#     jpegoptim optipng pngquant gifsicle \
#     unzip \
#     git \
#     curl \
#     lua-zlib-dev \
#     libmemcached-dev \
#     # mysql-server \
#     # default-mysql-client \
#     nginx \
#     supervisor

# # Add Composer
# RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer
# ENV COMPOSER_ALLOW_SUPERUSER=1
# ENV PATH="./vendor/bin:$PATH"

# # Setup Crond and Supervisor by default
# # RUN echo '*  *  *  *  * /usr/local/bin/php  /var/www/artisan schedule:run >> /dev/null 2>&1' > /etc/crontabs/root && mkdir /etc/supervisor.d
# ADD conf/supervisor/master.ini /etc/supervisor.d/
# ADD conf/nginx/default.conf /etc/nginx/conf.d/

# # PHP Error Log Files
# RUN mkdir /var/log/php
# RUN touch /var/log/php/errors.log && chmod 777 /var/log/php/errors.log

# WORKDIR /var/www


FROM php:8.0-local

RUN apk --no-cache add pcre-dev ${PHPIZE_DEPS} libressl-dev pkgconfig libevent-dev libzip-dev && pecl install event && apk del pcre-dev ${PHPIZE_DEPS}
RUN docker-php-ext-install zip

COPY composer.json composer.json
COPY composer.lock composer.lock

RUN composer install --prefer-dist --no-scripts --no-autoloader && rm -rf /root/.composer

COPY --chown=www-data:www-data . .

RUN cp services.ini /etc/supervisor.d/

RUN chgrp -R www-data /var/www/storage /var/www/bootstrap/cache
RUN chmod -R 775 /var/www/storage /var/www/bootstrap/cache

RUN composer dump-autoload --no-scripts --optimize
RUN ln -s /var/www/storage/app/ /var/www/public/storage
RUN cp .env.dev .env
ENTRYPOINT [ "/usr/bin/supervisord" ]