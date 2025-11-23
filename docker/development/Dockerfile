# Development Dockerfile for FinNaslain Financial Solution
FROM node:18-alpine

WORKDIR /app

# Install development tools
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++ \
    curl

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev)
RUN npm install

# Copy application code
COPY . .

# Expose application port and debug port
EXPOSE 8080 9229

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:8080/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start in development mode with hot reload
CMD ["npm", "run", "dev"]
