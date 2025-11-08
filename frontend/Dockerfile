FROM node:20-alpine

RUN apk add --no-cache git su-exec

# Build arguments for user ID and group ID
ARG USER_ID=1000
ARG GROUP_ID=1000

# Create user with specified UID/GID
RUN addgroup -g ${GROUP_ID} appuser || true && \
    adduser -D -u ${USER_ID} -G appuser appuser || true

WORKDIR /app

# Copy entrypoint script and fix line endings (Windows CRLF -> Linux LF)
COPY docker-entrypoint.sh /tmp/docker-entrypoint.sh
RUN sed -i 's/\r$//' /tmp/docker-entrypoint.sh && \
    chmod +x /tmp/docker-entrypoint.sh && \
    mv /tmp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Set ownership of app directory
RUN chown -R ${USER_ID}:${GROUP_ID} /app || true

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
