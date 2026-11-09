# BUILD — willow-creek-hospital-cloud

## One-line install (fresh Ubuntu/Debian VM)

```bash
curl -fsSL https://raw.githubusercontent.com/UncleD0886475978/willow-creek-hospital-cloud/main/setup.sh | bash
```

The script installs its own prerequisites — git/curl via apt, Terraform from the official HashiCorp apt repository, and Docker via the official get.docker.com script — then clones the repo and builds. Alternative (clone-and-run): `git clone https://github.com/UncleD0886475978/willow-creek-hospital-cloud.git && cd willow-creek-hospital-cloud && ./setup.sh`.

- Repo: UncleD0886475978/willow-creek-hospital-cloud — Public (not marked private/fork in brief)
- Stack actually found: Terraform/AWS + Flask + Docker + PostgreSQL. Proving files: `terraform/main.tf` (7,294 B), `terraform/variables.tf`, `app/app.py`, `app/Dockerfile`, `app/templates/`, `schema.sql`, `README.md` (VPC/EC2 portal/RDS Postgres Multi-AZ/S3/KMS/CloudTrail, staff-directory portal).
- What setup.sh does: Bootstraps base tools (git/curl) via apt, locates/clones the repo, bootstraps terraform (HashiCorp apt repo) and docker (get.docker.com, daemon start, `sudo docker` fallback) — on non-apt platforms it prints install guidance and exits — then runs `terraform init -backend=false` + `terraform validate` in `terraform/` (never apply), and `${DOCKER} build -t willow-creek-portal ./app` as a build check. Prints a bootstrap summary (installed tools, working copy, one-line reinstall command) and the deliberate plan/apply command. (Python is not bootstrapped: the Flask app runs inside the Docker image, and the script itself never calls python3.)
- Issue it prevents: Accidentally `terraform apply`-ing a HIPAA-scoped hospital stack (and its AWS bill) just to check the code works.
- Inspection note: root listing for every repo succeeded via GitHub connector. Deeper file reads were halted by a GitHub MCP HTTP 429 (rate limit) after willow-creek's subdirs/README were read; no further connector calls were made after the 429. Scripts therefore discover files at runtime where subdir contents were not individually enumerated. Willow subdirs/README were fully read before the limit.
