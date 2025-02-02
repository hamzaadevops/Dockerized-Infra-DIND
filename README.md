# Running the Container with Environment Variables
Pass environment variables when running the container:

```bash
docker run --privileged -it \
  -e DOMAIN="example.com" \
  -e PUBLIC_IP="192.168.1.1" \
  -e CLOUDFLARE_API_TOKEN="your-cloudflare-token" \
  custom-dind-image
```
