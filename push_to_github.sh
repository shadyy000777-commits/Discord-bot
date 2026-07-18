#!/bin/bash
# Usage:
#   bash push_to_github.sh bot     "commit message"   → pushes to Discord-bot
#   bash push_to_github.sh website "commit message"   → pushes to INDEX
set -e

TARGET="${1:-}"
COMMIT_MSG="${2:-Update from Replit}"

if [[ "$TARGET" != "bot" && "$TARGET" != "website" ]]; then
    echo "Usage: bash push_to_github.sh <bot|website> \"commit message\""
    echo "  bot     → pushes bot code to shadyy000777-commits/Discord-bot"
    echo "  website → pushes website files to shadyy000777-commits/INDEX"
    exit 1
fi

git config credential.helper store
git config user.email "aftershock@replit.com"
git config user.name "Aftershock Bot"

if [[ "$TARGET" == "bot" ]]; then
    REPO="Discord-bot"
    FILES="main.py config.py requirements.txt push_to_github.sh replit.md"
    echo "▶ Pushing bot changes to $REPO..."
else
    REPO="INDEX"
    FILES="railway_server.py Procfile railway.json nixpacks.toml runtime.txt requirements-web.txt website/index.html website/static"
    echo "▶ Pushing website changes to $REPO..."
fi

# Use a temp worktree so we never touch the local working tree
TMPDIR_WORK=$(mktemp -d)
trap "rm -rf $TMPDIR_WORK" EXIT

REMOTE_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/shadyy000777-commits/${REPO}"

# Clone only the target repo into the temp dir (shallow, fast)
git clone --depth=1 "$REMOTE_URL" "$TMPDIR_WORK/repo" 2>&1

# Copy the relevant files into the temp clone
for item in $FILES; do
    if [[ -e "$item" ]]; then
        dest="$TMPDIR_WORK/repo/$item"
        if [[ -d "$item" ]]; then
            # For directories: copy contents INTO dest (not dest/dirname)
            mkdir -p "$dest"
            cp -r "$item"/. "$dest/"
        else
            mkdir -p "$(dirname "$dest")"
            cp "$item" "$dest"
        fi
        echo "  copied $item"
    else
        echo "  ⚠ skipped $item (not found locally)"
    fi
done

# Commit and push from the temp clone
cd "$TMPDIR_WORK/repo"
git add -- $FILES
if ! git diff --cached --quiet; then
    git commit -m "$COMMIT_MSG"
    echo "✅ Committed: $COMMIT_MSG"
else
    echo "ℹ️  Nothing new to commit."
fi

git push origin main
echo "✅ Pushed to $REPO."
