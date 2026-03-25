# Native Docker Engine Guide for Ubuntu

## What is Native Docker Engine?

**Native Docker Engine** is the core Docker daemon that runs directly on your Linux system without any virtualization layer or GUI application.

### Docker Desktop vs Native Docker Engine

| Feature | Docker Desktop | Native Docker Engine |
|---------|---------------|---------------------|
| Installation | GUI Application | System Service |
| Performance | Slower (uses VM) | Faster (native) |
| Resource Usage | Higher | Lower |
| GUI | ✅ Yes | ❌ No (CLI only) |
| Stability on Linux | Can have issues | Rock solid |
| Best for | Mac/Windows | Linux |

---

## Installation

### 1. Remove Docker Desktop (if installed)

```bash
# Stop Docker Desktop
# Close it from system tray

# Remove Docker Desktop
sudo apt remove docker-desktop

# Clean up configs
rm -rf ~/.docker/desktop
rm -rf ~/.docker/contexts/desktop-linux
```

### 2. Install Native Docker Engine

```bash
# Update package list
sudo apt update

# Install Docker Engine
sudo apt install -y docker.io

# Optional: Install Docker Compose v2
sudo apt install -y docker-compose-v2
```

### 3. Start Docker Service

```bash
# Start Docker
sudo systemctl start docker

# Enable auto-start on boot (optional)
sudo systemctl enable docker

# Check status
sudo systemctl status docker
```

### 4. Add Your User to Docker Group

This allows you to run Docker commands without `sudo`.

```bash
# Add yourself to docker group
sudo usermod -aG docker $USER

# Apply changes (choose one):
# Option A: Temporary for current terminal
newgrp docker

# Option B: Log out and log back in (recommended)
# Option C: Reboot your system
```

### 5. Verify Installation

```bash
# Check Docker version
docker --version

# Test Docker
docker run hello-world

# Check running containers
docker ps
```

---

## Essential Docker Commands

### Managing Docker Service

```bash
# Start Docker
sudo systemctl start docker

# Stop Docker
sudo systemctl stop docker

# Restart Docker
sudo systemctl restart docker

# Check status
sudo systemctl status docker

# Enable auto-start on boot
sudo systemctl enable docker

# Disable auto-start on boot
sudo systemctl disable docker

# Check if Docker is enabled
systemctl is-enabled docker
```

### Basic Container Commands

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Run a container
docker run <image-name>

# Run container in background (detached mode)
docker run -d <image-name>

# Run container with custom name
docker run --name my-container <image-name>

# Stop a container
docker stop <container-id-or-name>

# Start a stopped container
docker start <container-id-or-name>

# Remove a container
docker rm <container-id-or-name>

# Remove all stopped containers
docker container prune
```

### Image Management

```bash
# List downloaded images
docker images

# Pull an image from Docker Hub
docker pull <image-name>:<tag>

# Remove an image
docker rmi <image-name>

# Remove unused images
docker image prune

# Remove all unused images (not just dangling)
docker image prune -a
```

### Docker Compose Commands

```bash
# Start services defined in docker-compose.yml
docker compose up

# Start in background
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs

# Rebuild services
docker compose up --build
```

### Viewing Logs

```bash
# View container logs
docker logs <container-id-or-name>

# Follow logs in real-time
docker logs -f <container-id-or-name>

# View last 100 lines
docker logs --tail 100 <container-id-or-name>
```

### Container Shell Access

```bash
# Execute command in running container
docker exec <container-id> <command>

# Access container shell (bash)
docker exec -it <container-id> bash

# Access container shell (sh - for Alpine Linux)
docker exec -it <container-id> sh
```

### System Cleanup

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Remove everything unused (careful!)
docker system prune

# Remove everything including volumes
docker system prune -a --volumes
```

---

## Common Use Cases

### Running Supabase

```bash
# Start Supabase local development
npx supabase start

# Stop Supabase
npx supabase stop

# Check Supabase status
npx supabase status
```

### Running PostgreSQL Database

```bash
# Run PostgreSQL container
docker run -d \
  --name my-postgres \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -p 5432:5432 \
  postgres:15

# Connect to the database
docker exec -it my-postgres psql -U postgres
```

### Running Redis

```bash
# Run Redis container
docker run -d \
  --name my-redis \
  -p 6379:6379 \
  redis:latest
```

### Running Node.js Application

```bash
# Run Node.js app with volume mount
docker run -d \
  --name my-node-app \
  -v $(pwd):/app \
  -w /app \
  -p 3000:3000 \
  node:18 \
  npm start
```

---

## Troubleshooting

### Permission Denied Error

If you get "permission denied" when running Docker commands:

```bash
# Make sure you're in the docker group
groups

# If 'docker' is not in the list, add yourself:
sudo usermod -aG docker $USER

# Then log out and log back in, or run:
newgrp docker
```

### Docker Desktop Credential Helper Error

If you see `docker-credential-desktop` error:

```bash
# Edit Docker config
nano ~/.docker/config.json

# Remove the "credsStore" line, or replace file content with:
{
  "currentContext": "default"
}
```

### Docker Service Not Starting

```bash
# Check Docker service status
sudo systemctl status docker

# View detailed logs
sudo journalctl -u docker

# Try restarting
sudo systemctl restart docker
```

### Port Already in Use

```bash
# Find what's using the port
sudo lsof -i :5432

# Or use netstat
sudo netstat -tulpn | grep 5432

# Stop the container using that port
docker stop <container-id>
```

### Check Docker Storage Space

```bash
# Check disk usage
docker system df

# Check detailed usage
docker system df -v
```

---

## Configuration Files

### Docker Daemon Config

Located at: `/etc/docker/daemon.json`

```bash
# Edit daemon config (requires sudo)
sudo nano /etc/docker/daemon.json

# After editing, restart Docker
sudo systemctl restart docker
```

Example configuration:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

### User Docker Config

Located at: `~/.docker/config.json`

This stores your personal Docker settings (no sudo needed):
```bash
nano ~/.docker/config.json
```

---

## Best Practices

1. **Always use specific image tags** instead of `latest`
   ```bash
   # Good
   docker run postgres:15
   
   # Avoid
   docker run postgres:latest
   ```

2. **Clean up regularly** to save disk space
   ```bash
   docker system prune -a
   ```

3. **Use `.dockerignore`** in your projects to exclude unnecessary files

4. **Name your containers** for easier management
   ```bash
   docker run --name my-app nginx
   ```

5. **Use Docker Compose** for multi-container applications

6. **Check logs** when something goes wrong
   ```bash
   docker logs container-name
   ```

---

## Quick Reference Card

```bash
# Service Management
sudo systemctl start docker        # Start Docker
sudo systemctl stop docker         # Stop Docker
sudo systemctl status docker       # Check status

# Containers
docker ps                          # List running containers
docker ps -a                       # List all containers
docker stop <id>                   # Stop container
docker rm <id>                     # Remove container
docker logs <id>                   # View logs
docker exec -it <id> bash          # Access shell

# Images
docker images                      # List images
docker pull <image>                # Download image
docker rmi <image>                 # Remove image

# Cleanup
docker system prune                # Clean up unused resources
docker container prune             # Remove stopped containers
docker image prune                 # Remove unused images

# Info
docker info                        # System-wide information
docker stats                       # Live container stats
docker --version                   # Docker version
```

---

## Getting Help

```bash
# General help
docker --help

# Command-specific help
docker run --help
docker compose --help

# View Docker info
docker info

# Check Docker version
docker version
```

---

## Additional Resources

- [Official Docker Documentation](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/) - Find container images
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Awesome Docker](https://github.com/veggiemonk/awesome-docker) - Curated list of Docker resources

---

## Summary

**Native Docker Engine** is the standard way to run Docker on Linux. It's:
- ✅ Faster than Docker Desktop
- ✅ More stable
- ✅ Uses fewer resources
- ✅ Better integrated with Linux
- ✅ The choice of most Linux developers

You control it entirely through the terminal, which gives you more power and flexibility. Once you get used to the commands, you'll find it much more efficient than GUI-based solutions.