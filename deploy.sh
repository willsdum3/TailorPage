#!/bin/bash

# Docker Deployment Script for Tailor Page App

echo "🚀 Starting Docker deployment..."

# Build the Docker image
echo "📦 Building Docker image..."
docker build -t tailorpage .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

echo "✅ Docker image built successfully!"

# Stop any existing container
echo "🛑 Stopping existing container..."
docker stop tailorpage-container 2>/dev/null || true
docker rm tailorpage-container 2>/dev/null || true

# Run the container
echo "🏃 Running container..."
docker run -d \
  --name tailorpage-container \
  -p 3000:80 \
  tailorpage

if [ $? -ne 0 ]; then
    echo "❌ Failed to run container!"
    exit 1
fi

echo "✅ Container started successfully!"
echo "🌐 Your app is now running at: http://localhost:3000"
echo ""
echo "📋 Container status:"
docker ps | grep tailorpage-container 