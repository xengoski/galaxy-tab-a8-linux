#!/bin/bash
# ==============================================================================
# Helper Script to Push Repository to GitHub (xengoski/samsung-gta8-linux)
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${REPO_DIR}"

echo "=================================================================="
echo " Pushing samsung-gta8-linux to github.com/xengoski/samsung-gta8-linux"
echo "=================================================================="

# Check if SSH key is registered
echo "[*] Checking GitHub SSH authentication..."
if ssh -T -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "[+] GitHub SSH authentication successful!"
    git remote set-url origin git@github.com:xengoski/samsung-gta8-linux.git
    echo "[*] Pushing main branch..."
    git push -u origin main
    echo "[+] Successfully pushed to GitHub!"
    exit 0
fi

echo "[-] GitHub SSH publickey authentication not yet configured."
echo ""
echo "Option 1: Add your SSH public key to GitHub (Recommended)"
echo "--------------------------------------------------------"
if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    echo "Your public key is:"
    echo "------------------------------------------------------------------"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo "------------------------------------------------------------------"
    echo "1. Go to: https://github.com/settings/keys"
    echo "2. Click 'New SSH key', paste the line above, and save."
    echo "3. Run ./push-to-github.sh again!"
fi

echo ""
echo "Option 2: Push via GitHub CLI or HTTPS Personal Access Token"
echo "--------------------------------------------------------"
echo "Run:"
echo "  gh auth login"
echo "  git push -u origin main"
echo "Or:"
echo "  git remote set-url origin https://github.com/xengoski/samsung-gta8-linux.git"
echo "  git push -u origin main"
echo ""
