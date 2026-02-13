# --- Build stage ---
FROM node:20-alpine AS builder

# Upgrade Alpine packages to fix CVEs
RUN apk update && apk add --no-cache libpng=1.6.54-r0 bash

WORKDIR /app

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy app source
COPY . .

# Build-time API env vars (non-secret)
ARG VITE_API_AUTH
ARG VITE_API_CATALOG
ARG VITE_API_CART
ARG VITE_API_ORDERS
ARG VITE_API_PAYMENTS
ARG VITE_STRIPE_KEY

# ⚠️ Check Stripe key at build time
RUN if [ -z "$VITE_STRIPE_KEY" ]; then \
      echo "❌ ERROR: VITE_STRIPE_KEY is not set! Aborting build." && exit 1; \
    else \
      echo "✅ VITE_STRIPE_KEY is set"; \
    fi

ENV VITE_API_AUTH=$VITE_API_AUTH
ENV VITE_API_CATALOG=$VITE_API_CATALOG
ENV VITE_API_CART=$VITE_API_CART
ENV VITE_API_ORDERS=$VITE_API_ORDERS
ENV VITE_API_PAYMENTS=$VITE_API_PAYMENTS
ENV VITE_STRIPE_KEY=$VITE_STRIPE_KEY

# Build the React/Vite app
RUN yarn build

# --- Runtime stage ---
FROM nginx:alpine

# Upgrade packages
RUN apk update && apk add --no-cache libpng=1.6.54-r0

# Copy build output
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]


# docker build \
#   --build-arg VITE_API_CATALOG=http://api.localdev.me/catalog \
#   --build-arg VITE_API_AUTH=http://api.localdev.me/auth \
#   --build-arg VITE_API_CART=http://api.localdev.me/cart \
#   --build-arg VITE_API_ORDERS=http://api.localdev.me/orders \
#   --build-arg VITE_API_PAYMENTS=http://api.localdev.me/payments \
#   --build-arg VITE_STRIPE_KEY=YOUR_STRIPE_KEY_HERE \
#   -t devopsflow999/frontend:901 .

#

# docker build -t devopsflow999/frontend:909 \
#   --build-arg VITE_API_AUTH=http://api.localdev.me/auth \
#   --build-arg VITE_API_CATALOG=http://api.localdev.me/catalog \
#   --build-arg VITE_API_CART=http://api.localdev.me/cart \
#   --build-arg VITE_API_ORDERS=http://api.localdev.me/orders \
#   --build-arg VITE_API_PAYMENTS=http://api.localdev.me/payments \
#   --build-arg VITE_STRIPE_KEY=pk_test_************* \
#   .

#


# docker build -t devopsflow999/frontend:910 \
#   --build-arg VITE_API_AUTH=https://api.travelersources.com/auth \
#   --build-arg VITE_API_CATALOG=https://api.travelersources.com/catalog \
#   --build-arg VITE_API_CART=https://api.travelersources.com/cart \
#   --build-arg VITE_API_ORDERS=https://api.travelersources.com/orders \
#   --build-arg VITE_API_PAYMENTS=https://api.travelersources.com/payments \
#   --build-arg VITE_STRIPE_KEY=stri \
#   .
