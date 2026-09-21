FROM php:8.4-fpm

# Cài đặt dependencies
RUN apt-get update && apt-get install -y \
    zip unzip curl git \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    libicu-dev \
    && docker-php-ext-install pdo pdo_mysql zip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install gd intl exif \
    && docker-php-ext-install mysqli \
    && rm -rf /var/lib/apt/lists/*
# Cài đặt Xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Cài đặt Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set thư mục làm việc
WORKDIR /var/www/html

# Tạo user tpa với UID trùng với máy host (mặc định lấy 1000)
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID tpa && useradd -m -u $UID -g tpa -s /bin/bash tpa

# Đổi cấu hình mặc định của PHP-FPM từ www-data sang user tpa
RUN sed -i 's/www-data/tpa/g' /usr/local/etc/php-fpm.d/www.conf

# **Cấp quyền truy cập đúng cho Laravel**
RUN mkdir -p /var/www/html/storage /var/www/html/bootstrap/cache \
    && chown -R tpa:tpa /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

USER root
CMD ["php-fpm"]
