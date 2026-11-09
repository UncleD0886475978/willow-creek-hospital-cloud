#!/usr/bin/env bash
set -e
REPO="willow-creek-hospital-cloud"
echo "=== Setup: $REPO ==="

OWNER="UncleD0886475978"
# --- Locate or clone ---
echo "==> Step: locate repo"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git remote -v 2>/dev/null | grep -q "$REPO"; then
  REPO_DIR="$(git rev-parse --show-toplevel)"; echo "Using current checkout: $REPO_DIR"
elif [ -d "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.git" ] && [ "$(basename "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")" = "$REPO" ]; then
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; echo "Using script location: $REPO_DIR"
elif [ -d "$HOME/repos/$REPO/.git" ]; then
  REPO_DIR="$HOME/repos/$REPO"; echo "Updating $REPO_DIR"; git -C "$REPO_DIR" pull --ff-only || echo "WARN: git pull failed, using existing checkout"
else
  mkdir -p "$HOME/repos"; git clone "https://github.com/$OWNER/$REPO.git" "$HOME/repos/$REPO"; REPO_DIR="$HOME/repos/$REPO"
fi
cd "$REPO_DIR"; echo "Repo dir: $REPO_DIR"

echo "==> Step: check prerequisites"
command -v git >/dev/null 2>&1 || { echo "Missing: git — install: https://git-scm.com/downloads"; exit 1; }

command -v terraform >/dev/null 2>&1 || { echo "Missing: terraform — install: https://developer.hashicorp.com/terraform/install"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Missing: docker — install: https://docs.docker.com/get-docker/"; exit 1; }
terraform version; docker --version


echo "==> Step: Terraform validate (terraform/ — VPC, EC2 portal, RDS Postgres Multi-AZ, S3, KMS, CloudTrail) — NEVER apply here"
(cd terraform && terraform init -backend=false && terraform validate)
echo "==> Step: Build staff-portal image (app/Dockerfile, Flask app/app.py) as a build check"
docker build -t willow-creek-portal ./app
echo "Note: schema.sql (departments/employees org schema) is loaded into RDS after a deliberate Terraform deploy — not applied by this script."
echo ""
echo "Deliberate deploy (NOT run):"
echo "  cd terraform && terraform plan -var=\"ami_id=ami-XXXXXXXX\" -var=\"key_name=your-key\" -var=\"db_password=CHANGEME\" && terraform apply"
echo "WARNING: terraform apply creates real AWS resources (RDS Multi-AZ, EC2, S3) that COST MONEY until destroyed. HIPAA-conscious design — do not put real PHI in this system."

echo ""
echo "=== Next commands ==="
echo "Run/use:  docker run -d -p 80:80 -e DB_HOST=<rds-endpoint> -e DB_NAME=willowcreek -e DB_USER=willowcreek_admin -e DB_PASS=<password> --name willow-creek-portal willow-creek-portal  # then open http://localhost/"
echo "Stop:     docker stop willow-creek-portal; (cloud) cd terraform && terraform destroy"
echo "Logs:     docker logs -f willow-creek-portal"
