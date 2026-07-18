# MCTiers Discord Bot

A self-contained Discord bot that replicates the MCTiers tier testing system for Minecraft PvP players. Supports slash commands and `!` prefix commands.

## Stack
- Python 3.12
- discord.py — slash commands, prefix commands, embeds
- python-dotenv — loads `DISCORD_TOKEN` from environment
- aiohttp — async HTTP

## Required secrets
- `DISCORD_TOKEN` — Discord bot token (required to run) — set in Replit as a secret

## Features
- `/test <gamemode>` — interactive tier test (crystal, sword, uhc, pot, axe, smp, bedwars, nodebuff)
- `/profile` — view tier profile
- `/leaderboard <gamemode>` — top tiered players
- `/setign <name>` — set Minecraft IGN
- `/tiers`, `/gamemodes`, `/help`
- Prefix equivalents: `!test`, `!profile`, `!lb`, `!tiers` (note: needs the "Message Content Intent" enabled in the Discord Developer Portal to work — see follow-up task)
- The same process also serves a companion tier-list website (Flask, `main.py` + `website/`) on port 5000, showing the leaderboard/rankings from `tiers_data.json`.

## How to run on Replit
The **Start application** workflow runs `railway_server.py` (the companion website) on port 5000 using `.venv/bin/python3`. Flask and waitress are installed in `.venv/` via `uv`. To reinstall: `uv venv --clear .venv && uv pip install --python .venv/bin/python3 flask waitress`.

The Discord bot runs on Railway only — NOT on Replit. Running `main.py` here would create a duplicate bot instance (same token). Verify bot changes with `python -m py_compile main.py`, then push to GitHub.

Note: `railway_server.py`, `Procfile`, and `railway.json` are the website-only Railway service (no Discord login) — a separate Railway service runs `main.py` for the actual bot.

## User preferences
- After committing changes to Discord bot code/commands (`main.py`, `config.py`, `requirements.txt`), always run `bash push_to_github.sh "<commit message>"` so those changes are pushed to the `Discord-bot` GitHub repo (and `AFTERSHOCK-TIERS`).
- `tiers_data.json`, root-level `index.html`, root-level `static/` and `skins/` are live-synced directly by the running production bot itself (via the GitHub Contents API, see `_push_data_to_github`/`_push_website_to_github`/`_push_image_to_github` in `main.py`) to `AFTERSHOCK-TIERS`, `My-site`, and `INDEX` on every change (e.g. every `/submittest`). `push_to_github.sh` must never commit or push these root-level files — this repl's local copies are stale dev snapshots, and force-pushing them would overwrite live production data and make it look like website updates are being reverted.
- **Two separate `index.html` copies exist and serve two different sites** — always edit both (or copy one over the other) when changing site design/markup:
  - Root `index.html` — pushed live by the bot itself (see above) to feed the **Netlify** site (`My-site`/`INDEX` repos). Never pushed by `push_to_github.sh`.
  - `website/index.html` (+ `website/static/`) — the file Railway's `railway_server.py` actually serves (per `Procfile: web: python railway_server.py`). The bot does **not** keep this one in sync; it only updates via a real git push. `push_to_github.sh` explicitly includes `website/index.html`/`website/static` in its code-file list so Railway's site picks up design changes.
- Do this automatically after relevant changes — don't wait to be asked to push each time.
