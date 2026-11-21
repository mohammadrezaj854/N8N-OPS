#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${N8N_OPS_REPO:-mohammadrezaj854/N8N-OPS}"
BRANCH="${N8N_OPS_BRANCH:-main}"
INSTALL_DIR="/opt/n8n-ops"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash install.sh"
  exit 1
fi

if [[ "$REPO" == "YOUR_GITHUB_USER/N8N-OPS" ]]; then
  echo "Edit REPO in install.sh after uploading this project to GitHub."
  echo "Or run: N8N_OPS_REPO=username/repository bash install.sh"
  exit 2
fi

URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"
echo "[*] Downloading N8N-OPS from ${URL}"
if command -v curl >/dev/null 2>&1; then
  curl -fL --retry 3 "$URL" -o "$TMP_DIR/repo.tar.gz"
else
  apt-get update && apt-get install -y curl ca-certificates
  curl -fL --retry 3 "$URL" -o "$TMP_DIR/repo.tar.gz"
fi
tar -xzf "$TMP_DIR/repo.tar.gz" -C "$TMP_DIR"
SRC="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)"
[[ -n "$SRC" && -f "$SRC/n8n-ops" ]] || { echo "Invalid repository archive"; exit 3; }

mkdir -p "$INSTALL_DIR"
cp -a "$SRC/." "$INSTALL_DIR/"
chmod 750 "$INSTALL_DIR/n8n-ops" "$INSTALL_DIR/scripts/"*.sh
ln -sfn "$INSTALL_DIR/n8n-ops" /usr/local/bin/n8n-ops

echo "[+] Installed to $INSTALL_DIR"
echo "[+] Start with: n8n-ops"
echo "[!] This step only installs the manager; it does not alter existing n8n data."
