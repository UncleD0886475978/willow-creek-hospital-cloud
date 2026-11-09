# BUILD — willow-creek-hospital-cloud

- Repo: UncleD0886475978/willow-creek-hospital-cloud — Public (not marked private/fork in brief)
- Stack actually found: Terraform/AWS + Flask + Docker + PostgreSQL. Proving files: `terraform/main.tf` (7,294 B), `terraform/variables.tf`, `app/app.py`, `app/Dockerfile`, `app/templates/`, `schema.sql`, `README.md` (VPC/EC2 portal/RDS Postgres Multi-AZ/S3/KMS/CloudTrail, staff-directory portal).
- What setup.sh does: Locates/clones the repo, checks git/terraform/docker, runs `terraform init -backend=false` + `terraform validate` in `terraform/` (never apply), and `docker build -t willow-creek-portal ./app` as a build check. Prints the deliberate plan/apply command.
- Issue it prevents: Accidentally `terraform apply`-ing a HIPAA-scoped hospital stack (and its AWS bill) just to check the code works.
- Inspection note: root listing for every repo succeeded via GitHub connector. Deeper file reads were halted by a GitHub MCP HTTP 429 (rate limit) after willow-creek's subdirs/README were read; no further connector calls were made after the 429. Scripts therefore discover files at runtime where subdir contents were not individually enumerated. Willow subdirs/README were fully read before the limit.
