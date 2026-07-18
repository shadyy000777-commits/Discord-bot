#!/bin/bash
# Push changes to the correct GitHub repo.
# Works by cloning the target repo into a temp dir, copying files in, then pushing.
# The local workspace is NEVER modified — no git reset, no stash, no pull.
#
# Usage:
#   bash push_to_github.sh bot     "commit message"   → pushes to Discord-bot
#   bash push_to_github.sh website "commit message"   → pushes to INDEX

set -e

TARGET="${1}"
COMMIT_MSG="${2:-Update from Replit}"
TMPDIR=$(mktemp -d)

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

git_cfg() {
  git -C "$TMPDIR" config user.email "aftershock@replit.com"
  git -C "$TMPDIR" config user.name "Aftershock Bot"
}

if [ "$TARGET" = "bot" ]; then
  REPO="Discord-bot"
  FILES="main.py config.py requirements.txt push_to_github.sh replit.md"

  echo "▶ Cloning ${REPO}..."
  git clone --depth 1 "https://x-access-token:${GITHUB_TOKEN}@github.com/shadyy000777-commits/${REPO}" "$TMPDIR" -q
  git_cfg

  for f in $FILES; do
    [ -e "$f" ] && cp -r "$f" "$TMPDIR/$f" && echo "  copied $f"
  done

  git -C "$TMPDIR" add .
  if ! git -C "$TMPDIR" diff --cached --quiet; then
    git -C "$TMPDIR" commit -m "$COMMIT_MSG"
    git -C "$TMPDIR" push origin main
    echo "✅ Pushed to ${REPO}."
  else
    echo "ℹ️  Nothing new to commit in ${REPO}."
  fi

elif [ "$TARGET" = "website" ]; then
  REPO="INDEX"
  echo "▶ Cloning ${REPO}..."
  git clone --depth 1 "https://x-access-token:${GITHUB_TOKEN}@github.com/shadyy000777-commits/${REPO}" "$TMPDIR" -q
  git_cfg

  # Copy website files — only those that exist locally
  for f in railway_server.py Procfile railway.json nixpacks.toml runtime.txt; do
    [ -e "$f" ] && cp "$f" "$TMPDIR/$f" && echo "  copied $f"
  done
  [ -d "website" ] && cp -r website/. "$TMPDIR/website/" && echo "  copied website/"

  git -C "$TMPDIR" add .
  if ! git -C "$TMPDIR" diff --cached --quiet; then
    git -C "$TMPDIR" commit -m "$COMMIT_MSG"
    git -C "$TMPDIR" push origin main
    echo "✅ Pushed to ${REPO}."
  else
    echo "ℹ️  Nothing new to commit in ${REPO}."
  fi

else
  echo "❌  Usage: bash push_to_github.sh <bot|website> \"commit message\""
  echo ""
  echo "  bot     → pushes main.py, config.py, requirements.txt, etc. to Discord-bot"
  echo "  website → pushes website/, railway_server.py, etc. to INDEX"
  exit 1
fi
