FROM php:8.3-cli

# Build arguments for user ID and group ID
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    dos2unix \
    gosu \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create user with specified UID/GID
RUN groupadd -g ${GROUP_ID} appuser || true && \
    useradd -u ${USER_ID} -g appuser -m -s /bin/bash appuser || true

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Set ownership of working directory
RUN chown -R ${USER_ID}:${GROUP_ID} /var/www/html || true

# Copy entrypoint script and fix line endings (Windows CRLF -> Linux LF)
COPY docker-entrypoint.sh /tmp/docker-entrypoint.sh
RUN dos2unix /tmp/docker-entrypoint.sh && \
    chmod +x /tmp/docker-entrypoint.sh && \
    mv /tmp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
