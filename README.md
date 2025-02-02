## First of try to pull the below images:
### Traefik:
```bash
   docker pull traefik:latest
```

### Portainer:
```bash
   docker pull portainer/portainer-ce
```

### One Click Application:
```bash
   docker pull hamzi3307/swiftroc:one_click
```

### Chat Service:
```bash
   docker pull bitnami/mongodb:6.0
   docker pull rocketchat/rocket.chat:latest
```

### Any Custom SSR Application:
```bash
   docker pull hamzi3307/swiftroc:dashboard
```


# Running the Container with Environment Variables
Pass environment variables when running the container:

```bash
docker run --privileged -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  hamzi3307/swiftroc:dind domain.com 12.34.56.78 cloudflare_profile_api_token
```
