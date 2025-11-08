FROM node:20-alpine

RUN apk add --no-cache git

WORKDIR /app

EXPOSE 3000

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
