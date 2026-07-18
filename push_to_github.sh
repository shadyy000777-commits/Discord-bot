#!/bin/bash
# Smart push: bot changes → Discord-bot repo, website changes → INDEX repo
# Never pushes to AFTERSHOCK-TIERS (that's Railway's auto-deploy source).
set -e

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN is not set. Add it as a Replit secret."
    exit 1
fi

COMMIT_MSG="${1:-Update from Replit}"
OWNER="shadyy000777-commits"
BOT_REPO="Discord-bot"
WEB_REPO="INDEX"
AUTH_URL_BASE="https://x-access-token:${GITHUB_TOKEN}@github.com/${OWNER}"

# ── File categories ──────────────────────────────────────────────────────────
# Files that belong to the bot repo
BOT_FILES=(
    main.py
    config.py
    requirements.txt
    requirements-web.txt
    runtime.txt
    Procfile
    railway.json
    railway_server.py
    push_to_github.sh
    replit.md
)
# Optional bot files (only copied if they exist)
BOT_FILES_OPTIONAL=(nixpacks.toml)

# Directories / files that belong to the website repo
WEB_DIRS=(website)

# ── Helpers ──────────────────────────────────────────────────────────────────
clone_and_push() {
    local label="$1"
    local repo="$2"
    local tmp_dir="$3"
    local copy_fn="$4"   # name of a shell function that copies files into $tmp_dir

    echo ""
    echo "▶ Checking ${label} (${repo})..."

    # Clone (quiet, depth 1 for speed)
    git clone --depth 1 --quiet "${AUTH_URL_BASE}/${repo}.git" "$tmp_dir" 2>/dev/null || {
        echo "  ⚠️  Could not clone ${repo}. Check GITHUB_TOKEN permissions."
        return 1
    }

    pushd "$tmp_dir" > /dev/null
    git config user.email "aftershock@replit.com"
    git config user.name "Aftershock Bot"
    popd > /dev/null

    # Copy the relevant files from the working directory into the clone
    "$copy_fn" "$tmp_dir"

    pushd "$tmp_dir" > /dev/null
    git add -A

    if git diff --cached --quiet; then
        echo "  ℹ️  No changes in ${label} — nothing to push."
    else
        git commit -m "$COMMIT_MSG"
        git push origin HEAD --quiet
        echo "  ✅ Pushed ${label} changes to ${OWNER}/${repo}"
    fi
    popd > /dev/null
}

# ── Copy functions ────────────────────────────────────────────────────────────
copy_bot_files() {
    local dest="$1"
    local src
    src="$(pwd)"   # Replit project root (we're not cd'd away yet)

    for f in "${BOT_FILES[@]}"; do
        [ -f "${src}/${f}" ] && cp "${src}/${f}" "${dest}/${f}"
    done
    for f in "${BOT_FILES_OPTIONAL[@]}"; do
        [ -f "${src}/${f}" ] && cp "${src}/${f}" "${dest}/${f}"
    done
}

copy_web_files() {
    local dest="$1"
    local src
    src="$(pwd)"

    for d in "${WEB_DIRS[@]}"; do
        if [ -e "${src}/${d}" ]; then
            # Merge local files INTO the clone without deleting anything already
            # in the remote. This prevents stale local copies from wiping live
            # content that the bot syncs directly (bg images, skins, etc.).
            mkdir -p "${dest}/${d}"
            cp -r "${src}/${d}/." "${dest}/${d}/"
        fi
    done
}

# ── Main ──────────────────────────────────────────────────────────────────────
PROJECT_ROOT="$(pwd)"
TMP_BOT="$(mktemp -d)"
TMP_WEB="$(mktemp -d)"
trap 'rm -rf "$TMP_BOT" "$TMP_WEB"' EXIT

# We stay in the project root so copy functions can reference it
cd "$PROJECT_ROOT"

clone_and_push "Bot code" "$BOT_REPO" "$TMP_BOT" copy_bot_files
clone_and_push "Website"  "$WEB_REPO" "$TMP_WEB" copy_web_files

echo ""
echo "Done."
