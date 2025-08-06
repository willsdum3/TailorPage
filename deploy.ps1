# Docker Deployment Script for Tailor Page App (PowerShell)

Write-Host "Starting Docker deployment..." -ForegroundColor Green

# Build the Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t tailorpage .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Docker image built successfully!" -ForegroundColor Green

# Stop any existing container
Write-Host "Stopping existing container..." -ForegroundColor Yellow
docker stop tailorpage-container 2>$null
docker rm tailorpage-container 2>$null

# Run the container
Write-Host "Running container..." -ForegroundColor Yellow
docker run -d --name tailorpage-container -p 3001:80 tailorpage

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to run container!" -ForegroundColor Red
    exit 1
}

Write-Host "Container started successfully!" -ForegroundColor Green
Write-Host "Your app is now running at: http://localhost:3001" -ForegroundColor Cyan
Write-Host ""
Write-Host "Container status:" -ForegroundColor Yellow
docker ps | Select-String "tailorpage-container" 