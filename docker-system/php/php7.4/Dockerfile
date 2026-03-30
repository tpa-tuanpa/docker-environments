FROM php:7.2-fpm-alpine

RUN apk add \
        autoconf \
        gcc \
        g++ \
        make \
        libtool \
        pkgconfig \
        linux-headers \
        bash \
        curl \
        git \
        zip \
        unzip \
        gmp \
        gmp-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        libxml2-dev \
        imagemagick \
        imagemagick-dev \
        $PHPIZE_DEPS

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN docker-php-ext-install \
    bcmath \
    gmp \
    mbstring \
    pdo \
    pdo_mysql \
    sockets \
    fileinfo \
    simplexml \
    xml \
    zip 

RUN docker-php-ext-install gd
RUN docker-php-ext-install dom

RUN pecl install xdebug-2.9.8 && docker-php-ext-enable xdebug
COPY ./xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN pecl install imagick && docker-php-ext-enable imagick
RUN apk del autoconf build-base libtool imagemagick-dev

EXPOSE 9000

WORKDIR /var/www/html

RUN chown 1000:1000 /var/www/html

USER 1000
