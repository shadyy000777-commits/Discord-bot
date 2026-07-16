#!/bin/bash
# Push bot code to the Discord-bot GitHub repo.
# Railway auto-deploys from there — pushing here is all that's needed.
#
# Usage: bash push_to_github.sh "commit message"

set -e

COMMIT_MSG="${1:-Update from Replit}"
OWNER="shadyy000777-commits"
REPO="Discord-bot"
BASE_DIR="$(pwd)"

# Bot-only files to copy into the repo
BOT_FILES="main.py config.py requirements.txt push_to_github.sh replit.md"

# Website-only files that must be deleted from the repo if present
# (they cause Railway to run the wrong build/start command for the bot)
WEBSITE_ONLY="nixpacks.toml Procfile railway.json railway_server.py requirements-web.txt runtime.txt index.html website"

echo "▶ Pushing to $OWNER/$REPO ..."

TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

git clone --depth=1 "https://x-access-token:${GITHUB_TOKEN}@github.com/${OWNER}/${REPO}.git" "$TMP_DIR" 2>&1

# Copy bot files in
for item in $BOT_FILES; do
    if [ -e "$BASE_DIR/$item" ]; then
        dest="$TMP_DIR/$item"
        mkdir -p "$(dirname "$dest")"
        cp "$BASE_DIR/$item" "$dest"
    fi
done

# Write a bot-specific nixpacks.toml so Railway uses the right start command
cat > "$TMP_DIR/nixpacks.toml" <<'EOF'
[phases.install]
cmds = ["pip install -r requirements.txt"]

[start]
cmd = "python main.py"
EOF

# Remove website-only files from the repo clone so Railway stops using them
cd "$TMP_DIR"
for item in $WEBSITE_ONLY; do
    if [ -e "$item" ] && [ "$item" != "nixpacks.toml" ]; then
        git rm -rf "$item" 2>/dev/null || true
    fi
done

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

cd "$BASE_DIR"
rm -rf "$TMP_DIR"
trap - EXIT
