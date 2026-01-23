# --- Build stage ---
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy source and build-time env vars
COPY . .

# These build args will come from Helm or Docker build command
ARG VITE_API_AUTH
ARG VITE_API_CATALOG
ARG VITE_API_CART
ARG VITE_API_ORDERS
ARG VITE_API_PAYMENTS
ARG VITE_STRIPE_KEY

# Pass build args to Vite environment
ENV VITE_API_AUTH=$VITE_API_AUTH
ENV VITE_API_CATALOG=$VITE_API_CATALOG
ENV VITE_API_CART=$VITE_API_CART
ENV VITE_API_ORDERS=$VITE_API_ORDERS
ENV VITE_API_PAYMENTS=$VITE_API_PAYMENTS
ENV VITE_STRIPE_KEY=$VITE_STRIPE_KEY

# Build the React app
RUN yarn build

# --- Runtime stage ---
FROM nginx:alpine

# Copy built app to nginx html directory
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

