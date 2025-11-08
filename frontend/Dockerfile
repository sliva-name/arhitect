FROM node:20-alpine

RUN apk add --no-cache git

WORKDIR /app

# Copy entrypoint script separately to avoid .dockerignore issues
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
