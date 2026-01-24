FROM node:24-slim

WORKDIR /usr/src/app

COPY package.json yarn.lock ./

# Install ONLY production deps
RUN yarn install --production --frozen-lockfile

COPY . .

EXPOSE 3002

USER node

CMD ["node", "index.js"]
