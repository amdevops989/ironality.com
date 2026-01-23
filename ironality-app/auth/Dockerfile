# ===== Base image =====
FROM node:24-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Apply resolutions and install exact dependencies
RUN npm ci --legacy-peer-deps

# Copy source code
COPY . .

# Expose app port
EXPOSE 3002

# Start the app
CMD ["node", "index.js"]
