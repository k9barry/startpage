# syntax=docker/dockerfile:1
# -----------------------------------------------------------------------------
# k9barry/startpage
# -----------------------------------------------------------------------------
# Minimal image: lissy93/dashy with the PUBLIC conf.yml baked in so the server
# can just `docker compose pull && up -d` to deploy config changes.
#
# conf.private.yml is NOT in this image — it's gitignored and mounted at
# runtime only on hosts that need the Internal page. Keeping it out means
# internal hostnames/IPs never land on public Docker Hub.
# -----------------------------------------------------------------------------

# Pin to the 3.2 floating tag so we inherit base-image patches without
# unexpected major bumps. Match this to docker-compose.yml.
FROM lissy93/dashy:3.2

COPY conf.yml /app/user-data/conf.yml
