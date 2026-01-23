# ===== Base image =====
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files and lockfile for deterministic installs
COPY package.json ./

# Install exact dependencies
RUN npm ci --legacy-peer-deps

# Copy source code
COPY . .

# Expose app port
EXPOSE 3002

# Start the app
CMD ["node", "index.js"]
