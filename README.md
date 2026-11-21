# N8N-OPS

A menu-driven Bash manager for deploying and maintaining a single-VPS n8n stack.

## Included stack

- n8n (pinned version; default `2.48.7`)
- PostgreSQL 18 Alpine
- External Task Runners (version-matched with n8n)
- SearXNG
- Optional Caddy HTTPS reverse proxy
- Optional Xray container (requires user-supplied `xray/config.json`)
- Proxy environment configuration for n8n and runners
- Backup, update, diagnostics, logs, restart and safe container removal

## Important safety model

- Fresh installation refuses to overwrite an existing `/opt/n8n/compose.yaml`, `.env`, or known n8n containers.
- Existing data volumes are never removed by the manager.
- `docker compose down -v` is never used.
- `.env` is generated with random secrets and mode `0600`.
- n8n binds to `127.0.0.1:5678` by default. Use Caddy on 80/443 for public HTTPS.
- PostgreSQL, task-runner broker, and SearXNG are not published to the host.
- The Sandbox DinD service is intentionally not auto-enabled: the upstream sandbox runner is privileged and requires a separately reviewed configuration and sufficient RAM. See `docs/SANDBOX.md`.

## Supported systems

Ubuntu 22.04 / 24.04. Recommended: 2 vCPU and at least 4 GB RAM for the base stack. Sandbox DinD needs additional memory and disk.

## Upload to GitHub

1. Create a repository named `N8N-OPS`.
2. Upload the contents of this folder to the repository root.
3. Edit `install.sh`: replace `YOUR_GITHUB_USER/N8N-OPS` with your GitHub owner/repository.
4. Commit to the `main` branch.

## Install manager

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USER/N8N-OPS/main/install.sh | sudo bash
```

Then:

```bash
sudo n8n-ops
```

Alternative when the repo is private or GitHub raw is unavailable:

```bash
git clone https://github.com/YOUR_GITHUB_USER/N8N-OPS.git
cd N8N-OPS
sudo bash install.sh
```

## Fresh install

Menu:
1. Install prerequisites
2. Fresh install n8n + PostgreSQL + Runners + SearXNG

The n8n UI is bound to localhost only. Add a domain and Caddy for public HTTPS:
- DNS A record points to the VPS public IP.
- Ports 80 and 443 are reachable from the Internet.
- Menu option 9 configures n8n host/webhook URLs.
- Menu option 10 enables Caddy.

## Existing installation

Do not select fresh install. Use status and diagnostics first. The manager does not automatically replace an existing Compose project because doing so can change volume names, database settings, encryption keys, or workflow data.

For adopting an existing deployment:
1. Take a verified database backup.
2. Copy the existing Compose file and `.env` outside `/opt/n8n`.
3. Compare service names, image tags, volume names, encryption key, and database settings.
4. Keep the existing `N8N_ENCRYPTION_KEY`. Losing it can make stored credentials unreadable.
5. Preserve current PostgreSQL major version. PostgreSQL major upgrades require a dump/restore or documented upgrade process.
6. Only then manually migrate to the N8N-OPS template.

## Xray and proxy

Xray is an optional Compose profile. The manager will not invent or download a working proxy configuration: supply a valid client/server configuration at `/opt/n8n/xray/config.json`, then use menu option 13. Its sample ports are bound to loopback only. The container image is not version-pinned in this starter; pin a tested image digest/tag before production use.

For outbound proxy use, menu option 11 writes HTTP_PROXY/HTTPS_PROXY for n8n and task runners. Enter the reachable proxy address from inside Docker. On this user's previous setup that address was `http://172.18.0.1:18118`, but verify it on the target host before applying it. Do not proxy internal Docker service names; keep them in NO_PROXY.

A reverse SSH tunnel is intentionally not installed in the single-server topology. It was part of the earlier two-server design and is unnecessary when the public reverse proxy and n8n run on the same VPS. Caddy handles HTTPS locally.

## Backups

Backups are stored under `/opt/n8n/backups/` and include:
- `.env`
- Compose file
- `pg_dumpall` output when the expected Postgres container exists
- archive of `n8n_data` volume

Copy backups off the VPS. A local backup is not disaster recovery.

## Security notes

- Never commit `.env`, backups, API keys, tunnel keys, Xray configs with credentials, or TLS private keys.
- Do not expose ports 5679, 5432, 8080, 9090, or sandbox runner ports publicly.
- Do not use `latest` for n8n and runners in production.
- Review changes before upgrading.
- Keep SSH access restricted and use key authentication.
