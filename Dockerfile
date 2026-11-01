FROM composer:latest AS vendor

FROM php:8.4-trixie

ENV TZ="Asia/Jakarta"
ENV APP_URL=http://localhost:8000
ENV APP_NAME=Laravel
ENV DB_CONNECTION=mysql
ENV DB_HOST=localhost
ENV DB_PORT=3306

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

RUN apt-get -y update

RUN apt-get -y install --no-install-recommends \
    zip \
    unzip \
    curl \
    libpng-dev \
    libzip-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    locales \
    jpegoptim optipng pngquant gifsicle \
    libxml2-dev \
    libmagickwand-dev \
    imagemagick \
    libz-dev \
    libmemcached-tools \
    libmemcached-dev \
    libpq-dev \
    poppler-utils

RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN docker-php-ext-configure gd \
        --with-freetype=/usr/include/ \
        --with-jpeg=/usr/include/ \
        --with-webp=/usr/include/ \
    && docker-php-ext-configure intl \
    && pecl install imagick \
    && pecl install redis \
    && pecl install memcached \
    && docker-php-ext-install \
        iconv \
        intl \
        pdo \
        pdo_mysql \
        mysqli \
        zip \
        exif \
        pcntl \
        gd \
        pgsql \
        opcache \
        sockets \
    && docker-php-ext-enable \
        imagick \
        redis \
        memcached

RUN mkdir -p ${PHP_INI_DIR}/session

RUN chown -R www-data:www-data ${PHP_INI_DIR}/session

RUN mkdir -p ${PHP_INI_DIR}/temp

RUN chown -R www-data:www-data ${PHP_INI_DIR}/temp

RUN mkdir -p ${PHP_INI_DIR}/opcache

RUN chown -R www-data:www-data ${PHP_INI_DIR}/opcache

COPY dockerconfig/php.ini ${PHP_INI_DIR}/php.ini

COPY --from=vendor /usr/bin/composer /usr/bin/composer

RUN mkdir -p /app

WORKDIR /app

COPY . .

COPY .env.example .env

RUN composer install --no-interaction --prefer-dist --no-ansi

RUN php artisan key:generate --ansi

RUN chown -R www-data:www-data storage && chmod -R 777 storage

RUN chown -R www-data:www-data bootstrap/cache && chmod -R 777 bootstrap/cache

RUN php artisan test

EXPOSE 8000

CMD [ "php", "artisan", "serve", "--host=0.0.0.0", "--port=8000" ]