# Deploying to an Oracle Cloud Always Free VM

This guide uses one ARM VM and Docker Compose for Rails, PostgreSQL/pgvector,
Redis, and Sidekiq. It is intended for a learning/demo deployment.

## 1. VM requirements

Use an Always Free eligible Ampere A1 VM with Oracle Linux 9, an SSH key, and a
public IPv4 address. In the VM's network security list, allow inbound TCP 22 and
80/443 only. Keep SSH restricted to your own IP when possible. Do not expose
ports 3000, 5432, or 6379 to the public internet.

Free shape availability varies by region/account. Do not enable paid resources or
upgrade the account for this demo.

## 2. Install Docker and check out the app

Docker Engine and its Compose plugin are installed and verified on the current
Oracle Linux 9 VM. For a fresh server, follow Docker's official EL9 installation
instructions. Clone the deployment branch on the VM and enter its directory:

```sh
git clone --branch test-branch https://github.com/Gon4ar5/vacancy-search.git
cd vacancy-search
```

## 3. Configure secrets

Copy `env.production.example` to `.env.production` on the VM. Set a unique,
long `DB_PASSWORD`, and copy the existing Rails master key into
`RAILS_MASTER_KEY`. Add `OPENAI_API_KEY` only if you want AI-backed features.
Set `APP_DOMAIN` to `<your-public-ip-with-dashes>.sslip.io`, for example
`92-5-129-253.sslip.io` for `92.5.129.253`.
Restrict the file to the VM user (`chmod 600 .env.production`). Never commit it.

## 4. Build and start

```sh
sudo docker compose --env-file .env.production -f docker-compose.production.yml up -d --build
sudo docker compose --env-file .env.production -f docker-compose.production.yml ps
sudo docker compose --env-file .env.production -f docker-compose.production.yml logs -f web worker
```

Rails prepares the production database when the web container starts. Caddy
terminates HTTPS and proxies requests to Rails over the private Docker network.
In the OCI subnet security list, allow inbound TCP 80 and 443. Do not expose
ports 3000, 5432, or 6379 publicly.

## 5. Verify and maintain

Check `/up`, test a user-facing flow, and confirm Sidekiq is running before
calling the deployment complete. Back up PostgreSQL data and keep a copy off the
VM. The free compute tier can reclaim sufficiently idle instances, so this is
not a production availability guarantee.

To stop the stack without deleting data:

```sh
sudo docker compose --env-file .env.production -f docker-compose.production.yml down
```

Do not add `--volumes` unless you intend to delete the database and Redis data.
