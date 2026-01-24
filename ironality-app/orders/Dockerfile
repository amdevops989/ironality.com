# 1️⃣ Build stage: install dependencies with Node 24-slim
FROM node:24-slim AS builder

# Create app directory
WORKDIR /usr/src/app

# Copy package files
COPY package.json yarn.lock ./

# Install production dependencies only
RUN yarn install --production --frozen-lockfile

# Copy app code
COPY . .

# 2️⃣ Runtime stage: Distroless Node 24
FROM gcr.io/distroless/nodejs24-debian13

# Set working directory
WORKDIR /usr/src/app

# Copy production dependencies + app code from builder
COPY --from=builder /usr/src/app ./

# Expose port
EXPOSE 3004

# Use Distroless expects CMD to be JS file
CMD ["index.js"]
