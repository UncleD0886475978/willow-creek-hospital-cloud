#!/usr/bin/env bash
# setup.sh — willow-creek-hospital-cloud (Terraform/AWS + Flask + Docker)
# VM BOOTSTRAP: on a fresh Ubuntu/Debian VM this script INSTALLS its own
# prerequisites (git/curl, Terraform, Docker) and then validates/builds.
# Safe by design: Terraform is init + validate ONLY. Nothing is applied to AWS.
set -e
REPO="willow-creek-hospital-cloud"
echo "=== Setup: $REPO ==="

OWNER="UncleD0886475978"
RUN_ONELINE="curl -fsSL https://raw.githubusercontent.com/${OWNER}/${REPO}/main/setup.sh | bash"

echo "==> Step 1/5: Platform check + base bootstrap (git, curl)"
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "ERROR: this script needs root or sudo to install packages."
    exit 1
  fi
fi
APT=0
if [ "$(uname -s)" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then APT=1; fi
INSTALLED=""
APT_UPDATED=""
note_installed() { INSTALLED="${INSTALLED} $1"; }
apt_update_once() {
  if [ -z "${APT_UPDATED}" ]; then $SUDO apt-get update -y; APT_UPDATED=1; fi
}
apt_install() {
  apt_update_once
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "$@"
}
if [ "${APT}" -eq 1 ]; then
  BASE_PKGS=""
  command -v git >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} git"
  command -v curl >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} curl"
  [ -f /etc/ssl/certs/ca-certificates.crt ] || BASE_PKGS="${BASE_PKGS} ca-certificates"
  command -v gpg >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} gnupg"
  if [ -n "${BASE_PKGS}" ]; then
    echo "    Installing base tools:${BASE_PKGS}"
    # shellcheck disable=SC2086
    apt_install ${BASE_PKGS}
    note_installed "${BASE_PKGS}"
  else
    echo "    Base tools already present (git, curl, ca-certificates, gnupg)."
  fi
else
  echo "    Non-apt platform detected — bootstrap will only CHECK tools and print install guidance."
fi

# --- Per-tool installers ---
DOCKER="docker"
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    echo "    docker: already present ($(docker --version))"
  elif [ "${APT}" -eq 1 ]; then
    echo "    Installing Docker Engine via the official get.docker.com script..."
    curl -fsSL https://get.docker.com | $SUDO sh
    note_installed "docker"
  else
    return 1
  fi
  if ! docker info >/dev/null 2>&1 && ! $SUDO docker info >/dev/null 2>&1; then
    echo "    Starting the Docker daemon..."
    $SUDO systemctl enable --now docker 2>/dev/null || $SUDO service docker start 2>/dev/null || true
    for _i in $(seq 1 15); do
      if docker info >/dev/null 2>&1 || $SUDO docker info >/dev/null 2>&1; then break; fi
      sleep 2
    done
  fi
  if docker info >/dev/null 2>&1; then
    DOCKER="docker"
  elif $SUDO docker info >/dev/null 2>&1; then
    DOCKER="sudo docker"
    if [ "$(id -u)" -ne 0 ]; then
      $SUDO usermod -aG docker "$USER" 2>/dev/null || true
      echo "    NOTE: you were added to the 'docker' group (applies at next login); this run uses 'sudo docker'."
    fi
  else
    echo "ERROR: Docker is installed but the daemon could not be started."
    echo "       On a VM:  sudo systemctl start docker   |   In a container/WSL without systemd, Docker cannot run here."
    exit 1
  fi
  echo "    docker daemon OK (using: ${DOCKER})"
}
install_terraform() {
  if command -v terraform >/dev/null 2>&1; then echo "    terraform: already present ($(terraform version | head -n 1))"; return 0; fi
  [ "${APT}" -eq 1 ] || return 1
  echo "    Installing Terraform from the official HashiCorp apt repository..."
  curl -fsSL https://apt.releases.hashicorp.com/gpg | $SUDO gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "${VERSION_CODENAME}") main" | $SUDO tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
  $SUDO apt-get update -y
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y terraform
  note_installed "terraform"
}

# --- Locate or clone ---
echo "==> Step 2/5: locate repo"
if [ -f "$0" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
  SCRIPT_DIR="$PWD"
fi
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git remote -v 2>/dev/null | grep -q "$REPO"; then
  REPO_DIR="$(git rev-parse --show-toplevel)"; echo "Using current checkout: $REPO_DIR"
elif [ -d "${SCRIPT_DIR}/.git" ] && [ "$(basename "${SCRIPT_DIR}")" = "$REPO" ]; then
  REPO_DIR="${SCRIPT_DIR}"; echo "Using script location: $REPO_DIR"
elif [ -d "$HOME/repos/$REPO/.git" ]; then
  REPO_DIR="$HOME/repos/$REPO"; echo "Updating $REPO_DIR"; git -C "$REPO_DIR" pull --ff-only || echo "WARN: git pull failed, using existing checkout"
else
  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git is not installed. Install it: https://git-scm.com/downloads"
    exit 1
  fi
  mkdir -p "$HOME/repos"; git clone "https://github.com/$OWNER/$REPO.git" "$HOME/repos/$REPO"; REPO_DIR="$HOME/repos/$REPO"
fi
cd "$REPO_DIR"; echo "Repo dir: $REPO_DIR"

echo "==> Step 3/5: Bootstrap prerequisites (Terraform, Docker)"
MISSING_LIST=""
install_terraform || MISSING_LIST="${MISSING_LIST} terraform(https://developer.hashicorp.com/terraform/install)"
install_docker || MISSING_LIST="${MISSING_LIST} docker(https://docs.docker.com/get-docker/)"
if [ -n "${MISSING_LIST}" ]; then
  echo "ERROR: could not auto-install on this platform. Missing:${MISSING_LIST}"
  echo "Install the tool(s) manually, then re-run this script."
  exit 1
fi
terraform version; docker --version


echo "==> Step 4/5: Terraform validate (terraform/ — VPC, EC2 portal, RDS Postgres Multi-AZ, S3, KMS, CloudTrail) — NEVER apply here"
(cd terraform && terraform init -backend=false && terraform validate)
echo "==> Step 5/5: Build staff-portal image (app/Dockerfile, Flask app/app.py) as a build check"
# shellcheck disable=SC2086
${DOCKER} build -t willow-creek-portal ./app
echo "Note: schema.sql (departments/employees org schema) is loaded into RDS after a deliberate Terraform deploy — not applied by this script."
echo ""
echo "Deliberate deploy (NOT run):"
echo "  cd terraform && terraform plan -var=\"ami_id=ami-XXXXXXXX\" -var=\"key_name=your-key\" -var=\"db_password=CHANGEME\" && terraform apply"
echo "WARNING: terraform apply creates real AWS resources (RDS Multi-AZ, EC2, S3) that COST MONEY until destroyed. HIPAA-conscious design — do not put real PHI in this system."

cat <<EOF

=================== BOOTSTRAP SUMMARY ===================
Installed during this run:${INSTALLED:- (nothing — all tools were already present)}
Working copy: ${REPO_DIR}
Next time, set up from scratch on any fresh Ubuntu VM with one line:
  ${RUN_ONELINE}
=========================================================
EOF

echo ""
echo "=== Next commands ==="
echo "Run/use:  docker run -d -p 80:80 -e DB_HOST=<rds-endpoint> -e DB_NAME=willowcreek -e DB_USER=willowcreek_admin -e DB_PASS=<password> --name willow-creek-portal willow-creek-portal  # then open http://localhost/"
echo "Stop:     docker stop willow-creek-portal; (cloud) cd terraform && terraform destroy"
echo "Logs:     docker logs -f willow-creek-portal"
