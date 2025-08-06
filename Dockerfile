# Stage 1: Build the app
FROM node:20-alpine AS builder
WORKDIR /app

# Copy package files from project directory
COPY project/package.json project/package-lock.json ./
RUN npm ci

# Copy project source code
COPY project/ .

# Copy environment variables for build
COPY project/.env ./

RUN npm run build

# Stage 2: Serve with a lightweight web server
FROM nginx:alpine

# Copy built application from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy public assets (if they exist and are needed)
COPY --from=builder /app/public /usr/share/nginx/html/public

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]