# JAFCP Start Page

A self-hosted start page for Madison County Central Dispatch and the
cleaver.me homelab, powered by [Dashy](https://dashy.to).

Migrated April 2026 from the original
[crshd startpage](https://github.com/Crshd/Startpage) single-file HTML format
to Dashy's YAML-driven, status-checking, icon-pack-aware dashboard.

## Repo layout

```
.
├── conf.yml                     ← PUBLIC  — tracked in git (cleaver.me + SaaS)
├── conf.private.yml             ← PRIVATE — gitignored (internal hosts)
├── conf.private.example.yml     ← Template showing structure only
├── docker-compose.yml
├── .gitignore
├── user-data/                   ← Runtime volume (gitignored)
├── README.md
└── legacy/
    └── index.html               ← Original crshd-style start page, archived
```

Dashy loads `conf.yml` as the main page and follows its `pages:` reference
to `conf.private.yml`, which shows up as an **Internal** tab in the nav bar.
If `conf.private.yml` isn't on disk, the main page still loads; only the
Internal tab errors.

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

## First-time setup

Requires Docker + Docker Compose.

```bash
git clone git@github.com:k9barry/startpage.git
cd startpage

# Create your private config from the template
cp conf.private.example.yml conf.private.yml
# edit conf.private.yml with your actual internal items
# (a populated version will already exist on the production host)

docker compose up -d
# Dashy is now at http://<host>:4000
```

If `conf.private.yml` doesn't exist when `docker compose up` runs, Docker
will silently create an empty directory at that path and Dashy will fail
to parse it. Always create the file first.

## Behind Traefik

You already run Traefik at `traefik.jafcp.com`. Uncomment the `labels:` block
and remove `ports:` from `docker-compose.yml` to publish at
`https://start.jafcp.com` with an automatic Let's Encrypt cert.

> [!WARNING]
> If you mount `conf.private.yml`, the Internal page can expose internal
> hostnames, IPs, and service URLs to anyone who can access the dashboard.
> Do **not** publish Dashy at a public hostname unless you also restrict
> access to it.
>
> Protect the dashboard with at least one of:
> - Dashy authentication
> - Traefik auth middleware (for example, basic auth or forward auth)
> - A Traefik IP allowlist
> - VPN-only/private-network access
>
> If public access is required for the external links, keep the Internal tab
> behind one of the protections above, or do not mount `conf.private.yml` on
> the public instance.

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

This repository is derived from the original
[crshd startpage](https://github.com/Crshd/Startpage) (MIT, © 2010 Christian Brassat)
and is powered by [Dashy](https://dashy.to) (MIT, © Alicia Sykes).
See the [LICENSE](LICENSE) file for the full license text and upstream attribution.
