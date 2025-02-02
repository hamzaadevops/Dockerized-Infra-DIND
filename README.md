# 🚀 Deployment Guide
## 📥 Pull Required Docker Images
Before running the main container, ensure you have the following images pulled.

### 1️⃣ Traefik (Reverse Proxy):
```bash
   docker pull traefik:latest
```

### 2️⃣ Portainer (Container Management):
```bash
   docker pull portainer/portainer-ce
```

### 3️⃣ One-Click Application:
```bash
   docker pull hamzi3307/swiftroc:one_click
```

### 4️⃣ Chat Service (MongoDB & Rocket.Chat):
```bash
   docker pull bitnami/mongodb:6.0
   docker pull rocketchat/rocket.chat:latest
```

### 5️⃣ Custom SSR Application (Dashboard):
```bash
   docker pull hamzi3307/swiftroc:dashboard
```

### 🎯 Final Image (Main Container):
This is the image which will setup the whole infrastructure for us as demanded.
```bash
   hamzi3307/swiftroc:dind
```


## 🚀 Running the Container with Environment Variables
Pass environment variables when running the container:

```bash
docker run --privileged -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  hamzi3307/swiftroc:dind domain.com 12.34.56.78 cloudflare_profile_api_token
```
### Explanation of Parameters:
 - --privileged → Grants elevated privileges to the container.
 - -it → Runs the container interactively.
 - -v /var/run/docker.sock:/var/run/docker.sock → Allows the container to access the Docker daemon.
 - hamzi3307/swiftroc:dind → The final Docker image.
 - domain.com → Replace with your domain.
 - 12.34.56.78 → Replace with your server's public IP.
 - cloudflare_profile_api_token → Replace with your Cloudflare API token.

## 🎯 Notes
 - Ensure Docker is installed and running on your system before proceeding.
 - Update the environment variables according to your setup.
 - Make sure port 80 and 443 are open if using a reverse proxy.
