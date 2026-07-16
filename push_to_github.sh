#!/bin/bash
# Push all code changes to the Discord-bot GitHub repo.
# Railway auto-deploys from there — pushing here is all that's needed.
#
# Usage: bash push_to_github.sh "commit message"
#
# NOTE: root-level tiers_data.json, index.html, static/ and skins/ are live-synced
# by the running bot via the GitHub Contents API — never push those here.

set -e

COMMIT_MSG="${1:-Update from Replit}"
OWNER="shadyy000777-commits"
REPO="Discord-bot"
BASE_DIR="$(pwd)"

# Bot-only files — website config (nixpacks.toml, Procfile, railway.json,
# requirements-web.txt, railway_server.py) must NOT be pushed here or Railway's
# bot service will try to install web deps and run the wrong start command.
ALL_FILES="main.py config.py requirements.txt push_to_github.sh replit.md"

echo "▶ Pushing to $OWNER/$REPO ..."

TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

git clone --depth=1 "https://x-access-token:${GITHUB_TOKEN}@github.com/${OWNER}/${REPO}.git" "$TMP_DIR" 2>&1

for item in $ALL_FILES; do
    if [ -e "$BASE_DIR/$item" ]; then
        dest="$TMP_DIR/$item"
        mkdir -p "$(dirname "$dest")"
        if [ -d "$BASE_DIR/$item" ]; then
            cp -r "$BASE_DIR/$item/." "$dest/"
        else
            cp "$BASE_DIR/$item" "$dest"
        fi
    fi
done

cd "$TMP_DIR"
git config user.email "aftershock@replit.com"
git config user.name "Aftershock Bot"

git add -A
if ! git diff --cached --quiet; then
    git commit -m "$COMMIT_MSG"
    git push origin main
    echo "✅ Pushed to $OWNER/$REPO"
else
    echo "ℹ️  Nothing new to commit."
fi
