# Use Node.js 24 (matches your installed version)
FROM node:24-alpine

# Set working directory inside container
WORKDIR /app

# Copy package files first (for caching)
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy all source files
COPY . .

# Expose port
EXPOSE 3000

# Start the server
CMD ["node", "index.js"]