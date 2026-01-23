# ===== Base image =====
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package.json AND package-lock.json
COPY package.json package-lock.json ./

# Install dependencies exactly as in lockfile
RUN npm ci --legacy-peer-deps

# Copy all source code
COPY . .

# Expose app port
EXPOSE 3000

# Run the service
CMD ["node", "index.js"]
