# Docker Deployment Guide

This guide will help you deploy your Tailor Page App using Docker.

## Prerequisites

- Docker installed on your system
- Environment variables properly configured

## Quick Deployment

### Option 1: Using the Deployment Script (Recommended)

**For Windows (PowerShell):**
```powershell
.\deploy.ps1
```

**For Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh
```

### Option 2: Manual Deployment

1. **Build the Docker image:**
   ```bash
   docker build -t tailorpage .
   ```

2. **Run the container:**
   ```bash
   docker run -d -p 3001:80 --name tailorpage-container tailorpage
   ```

3. **Access the application:**
   Open your browser and go to `http://localhost:3001`

## Environment Variables

Make sure your `.env` file in the `project/` directory contains the correct environment variables:

```env
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
VITE_CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key
```

## Container Management

### View running containers:
```bash
docker ps
```

### Stop the container:
```bash
docker stop tailorpage-container
```

### Remove the container:
```bash
docker rm tailorpage-container
```

### View container logs:
```bash
docker logs tailorpage-container
```

### Restart the container:
```bash
docker restart tailorpage-container
```

## Troubleshooting

### Container won't start
1. Check if port 3000 is already in use:
   ```bash
   netstat -ano | findstr :3000
   ```
2. Stop any existing containers:
   ```bash
   docker stop $(docker ps -q)
   ```

### Environment variables not working
1. Verify your `.env` file is in the `project/` directory
2. Check that environment variable names use the `VITE_` prefix
3. Rebuild the Docker image after changing environment variables

### App not loading properly
1. Check container logs:
   ```bash
   docker logs tailorpage-container
   ```
2. Verify the build was successful:
   ```bash
   docker build -t tailorpage . --no-cache
   ```

### Performance Issues
- The app is optimized for production with nginx serving static files
- Static assets are cached for 1 year
- Client-side routing is properly configured

## Production Deployment

For production deployment, consider:

1. **Using environment variables at runtime:**
   ```bash
   docker run -d -p 3001:80 \
     -e VITE_SUPABASE_URL=your_url \
     -e VITE_SUPABASE_ANON_KEY=your_key \
     -e VITE_CLERK_PUBLISHABLE_KEY=your_key \
     --name tailorpage-container tailorpage
   ```

2. **Using Docker Compose for easier management:**
   Create a `docker-compose.yml` file for multi-container setups

3. **Setting up reverse proxy:**
   Use nginx or Apache as a reverse proxy for SSL termination

## Security Notes

- The Docker image includes security headers
- Environment variables are baked into the build (consider runtime injection for production)
- The app runs on port 80 inside the container, mapped to port 3000 on the host 