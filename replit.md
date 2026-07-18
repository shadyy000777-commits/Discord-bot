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
The Discord bot runs on Railway only now — NOT on Replit. Do not start the **Start application** workflow (`python main.py`) to "test" bot changes; running it here logs into Discord with the same `DISCORD_TOKEN` Railway uses, which causes duplicate/conflicting bot instances and made debugging harder.

Instead, verify code changes with a syntax/import check, e.g. `python -m py_compile main.py`, and push to GitHub (`bash push_to_github.sh`) so Railway picks up the change. Only start the workflow if the user explicitly asks to run the bot on Replit again.

Note: `railway_server.py`, `Procfile`, and `railway.json` are the website-only Railway service (no Discord login) — a separate Railway service runs `main.py` for the actual bot.

## User preferences
- Run `bash push_to_github.sh "<commit message>"` automatically after any relevant change — don't wait to be asked.
- **Push routing** — the script auto-detects what changed and routes to the correct repo only:
  - Bot changes (`main.py`, `config.py`, `requirements.txt`, `railway_server.py`, etc.) → `shadyy000777-commits/Discord-bot`
  - Website changes (`website/` directory) → `shadyy000777-commits/INDEX`
  - Never push to `AFTERSHOCK-TIERS` from Replit (that repo is Railway's auto-deploy source, untouched here).
- `tiers_data.json`, root-level `index.html`, root-level `static/` and `skins/` are live-synced directly by the running production bot itself (via the GitHub Contents API). `push_to_github.sh` must never touch these — this repl's local copies are stale dev snapshots.
- **Two separate `index.html` copies exist and serve two different sites** — always edit both when changing site design/markup:
  - Root `index.html` — pushed live by the bot to feed the **Netlify** site. Never touched by `push_to_github.sh`.
  - `website/index.html` (+ `website/static/`) — served by Railway's `railway_server.py`. Updated via `push_to_github.sh` → `INDEX` repo.
