# --- Build stage ---
FROM node:20-alpine AS builder

# Upgrade Alpine packages to fix CVEs (libpng etc.)
RUN apk update && apk add --no-cache libpng=1.6.54-r0

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

ENV VITE_API_AUTH=$VITE_API_AUTH
ENV VITE_API_CATALOG=$VITE_API_CATALOG
ENV VITE_API_CART=$VITE_API_CART
ENV VITE_API_ORDERS=$VITE_API_ORDERS
ENV VITE_API_PAYMENTS=$VITE_API_PAYMENTS

# Build the React/Vite app
RUN yarn build

# --- Runtime stage ---
FROM nginx:alpine

# update 
RUN apk update && apk add --no-cache libpng=1.6.54-r0


# Copy build output
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Stripe secret should be injected at runtime
ENV VITE_STRIPE_KEY=__STRIPE_KEY_PLACEHOLDER__

CMD ["nginx", "-g", "daemon off;"]
