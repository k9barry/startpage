# JAFCP Start Page

A self-hosted start page for Madison County Central Dispatch and the
cleaver.me homelab, powered by [Dashy](https://dashy.to).

Migrated April 2026 from the original
[crshd startpage](https://github.com/Crshd/Startpage) single-file HTML format
to Dashy's YAML-driven, status-checking, icon-pack-aware dashboard.

## Repo layout

```
.
├── conf.yml                          ← PUBLIC  — tracked (cleaver.me + SaaS)
├── conf.private.yml                  ← PRIVATE — gitignored (internal hosts)
├── conf.private.example.yml          ← Template showing structure only
├── Dockerfile                        ← Bakes conf.yml into a Dashy-based image
├── .dockerignore
├── docker-compose.yml                ← Local dev — upstream dashy + mounts
├── docker-compose.server.yml.example ← Server — pulls k9barry/startpage image
├── .github/workflows/docker-image.yml ← CI: build + push to Docker Hub
├── .gitignore
├── user-data/                        ← Runtime volume (gitignored)
├── README.md
├── LICENSE
└── legacy/
    └── index.html                    ← Original crshd-style start page, archived
```

Dashy loads `conf.yml` as the main page and follows its `pages:` reference
to `conf.private.yml`, which shows up as an **Internal** tab in the nav bar.

## What lives where

| Section                    | Count | File                |
| -------------------------- | ----- | ------------------- |
| Homelab — Cleaver.me       | 17    | `conf.yml`          |
| External Services          |  6    | `conf.yml`          |
| Motorola                   | 10    | `conf.yml`          |
| Dispatch — External        | 17    | `conf.yml`          |
| Madison County             |  9    | `conf.yml`          |
| Tyler SaaS                 |  4    | `conf.yml`          |
| Time & Attendance          |  3    | `conf.yml`          |
| State of Indiana           |  8    | `conf.yml`          |
| **Public total**           | **74** |                    |
| JAFCP Infrastructure       |  7    | `conf.private.yml`  |
| Motorola — Internal        |  4    | `conf.private.yml`  |
| Dispatch — Internal        |  5    | `conf.private.yml`  |
| Madison County — Internal  | 12    | `conf.private.yml`  |
| Tyler New World — Internal | 11    | `conf.private.yml`  |
| **Private total**          | **39** |                    |
| **Grand total**            | **113** |                   |

Anything with an RFC1918 IP, a `*.madison.local` domain, a bare internal
hostname (e.g. `nwpsappprd`, `confluence`, `s2netbox`), or a JAFCP.com
infrastructure subdomain (snipeit, dozzle, traefik, ntfy, sql, viavi, noaa)
is in the private file.

## Deployment modes

The repo supports two deployment patterns — pick whichever fits.

### Mode A: Pull prebuilt image (server / production)

This is how the production host deploys. GitHub Actions builds a Docker image
on every push to `master` that changes `conf.yml` or the Dockerfile, bakes the
public config in, and pushes to Docker Hub as `k9barry/startpage:latest`. The
server just pulls that image.

**On the server, one time:**

```bash
# Somewhere like /opt/startpage
curl -O https://raw.githubusercontent.com/k9barry/startpage/master/docker-compose.server.yml.example
mv docker-compose.server.yml.example docker-compose.yml

# Bootstrap the private config
curl -O https://raw.githubusercontent.com/k9barry/startpage/master/conf.private.example.yml
cp conf.private.example.yml conf.private.yml
# edit conf.private.yml with your real internal items

docker compose up -d
# Dashy is now at http://<host>:4000
```

**To deploy a config change:**

```bash
# Local:
git add conf.yml && git commit -m "..." && git push
# CI builds + pushes image (~2 min)

# On the server:
docker compose pull && docker compose up -d
```

Or install Watchtower once (sample block commented at the bottom of
`docker-compose.server.yml.example`) and config updates auto-deploy within 5
minutes of the image hitting Docker Hub.

### Mode B: Build locally from source (dev / testing / air-gapped)

Uses the upstream `lissy93/dashy:3.2` image and bind-mounts both config files.
Edits to `conf.yml` are reflected live (hot-reload on save), no rebuild needed.

```bash
git clone git@github.com:k9barry/startpage.git
cd startpage

# REQUIRED before first run — the private config mount is strict.
cp conf.private.example.yml conf.private.yml
# edit conf.private.yml with your actual internal items

docker compose up -d
# Dashy is now at http://<host>:4000
```

### Why the `cp` step is mandatory (both modes)

Both compose files bind-mount `./conf.private.yml` with
`create_host_path: false`. If the file isn't present, Compose refuses to
start with an error like:

```
error mounting "/.../conf.private.yml" to rootfs at
"/app/user-data/conf.private.yml": no such file or directory
```

This is deliberate — it prevents Docker's old "silently create a host
directory, then mount the empty dir as a YAML file, then fail mysteriously
inside the container" footgun. Loud failure, clear remedy.

### Public-only deployment (no internal links)

If you want to run just the public page (e.g. on a demo host, or because
you aren't on the Madison County network), remove two things:

1. The `pages:` block at the top of `conf.yml` (lines ~33–36).
2. The `conf.private.yml` bind mount in whichever compose file you're using.

Then `docker compose up -d` will work without bootstrapping a private
config.

## CI/CD pipeline

`.github/workflows/docker-image.yml` builds and pushes the image.

- **Triggers:** push to `master`/`main` that touches `conf.yml`, `Dockerfile`,
  `.dockerignore`, or the workflow itself; a weekly Monday 06:00 UTC schedule
  (to pick up upstream Dashy base-image patches); and manual
  `workflow_dispatch`.
- **Tags pushed:** `latest` (tracks default branch) and `sha-<short>`
  (pinnable for rollback).
- **Platforms:** `linux/amd64`, `linux/arm64`.
- **Required secrets:** `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`. Both carry
  over from the old repo; rotate via Docker Hub → Account Settings → Personal
  access tokens, then paste into Repo Settings → Secrets and variables →
  Actions.

The `.dockerignore` explicitly excludes `conf.private.yml` (and its example)
from the build context as a second layer of defense, in addition to git
ignoring it.

## Behind Traefik

You already run Traefik at `traefik.jafcp.com`. Uncomment the `labels:` block
in your compose file and remove `ports:` to publish at
`https://start.jafcp.com` with an automatic Let's Encrypt cert.

## Updating

```bash
docker compose pull
docker compose up -d
```

## Editing

Two workflows:

1. **Edit the YAML files in this repo**, commit public changes, push. The
   running container picks up saves instantly (files are bind-mounted). This
   is the infra-as-code path.
2. **Click the pencil icon in the Dashy UI** to edit visually. Changes write
   into the container's user-data volume and will overwrite the bind-mounted
   file. Pull changes back into git if you want them tracked.

Pick one; don't mix without care.

## What changed vs. the old `index.html`

- **Single-file plaintext → YAML-driven Dashy.** Hot-reload on save, no
  rebuild, UI editor available.
- **Duplicate `ntfy.jafcp.com` entry removed.**
- **Dispatch block split** into External vs. Internal.
- **Public / private config split** (this change) so the repo can stay
  public without leaking internal infrastructure.
- **Favicons everywhere.** selfh.st / Heimdall icon pack (`hl-*`), Font
  Awesome 6 for categorical items, `favicon` auto-fetch for the rest.
- **`microsoft-edge:` protocol handlers preserved** (Licensing Portal,
  ESInet, NICE Inform). Still only fire on Windows with Edge's protocol
  handler registered.
- **jQuery 1.11.0 dropped.** No more 2014-era unpatched JS reaching the
  browser.

## License

MIT, inherited from the original crshd startpage by Christian Brassat (2010).
Dashy is MIT-licensed by Alicia Sykes.
