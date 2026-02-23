# Claude Docker Linux

## Project overview
Dockerized Claude Code for Linux. Runs claude-code in isolated container with host filesystem access limited to `~/git`.

## Key architecture decisions
- **Auth**: OAuth via bind-mounted `~/.claude/.credentials.json` (from `claude login` on host). No API key.
- **GitHub auth**: `GH_TOKEN` env var from `.env` file. Host keyring not accessible from container, so `gh auth login` tokens don't work — must use personal access token with `repo` scope.
- **Config**: Both `~/.claude/` (dir) and `~/.claude.json` (file) must be mounted — claude-code uses both.
- **Persistence**: Named Docker volumes for pip (`~/.local`), conda (`/opt/conda`), uv cache. Survives container restarts.
- **Conda seed**: `/opt/conda` is a named volume (starts empty). Image keeps a copy at `/opt/conda.seed`, entrypoint seeds volume on first run.
- **SSH**: Host `~/.ssh` mounted read-only. Entrypoint copies to `/tmp/.ssh` with correct perms since node user can't read ro mount with host uid perms.
- **Permissions**: Container runs as `node` (uid 1000). Has passwordless sudo. Claude runs with `--dangerously-skip-permissions`.
- **Auto-update**: claude-code updated via `sudo npm install -g` in entrypoint on every container start.
- **gh config**: Must mount individual files (`hosts.yml`, `config.yml`) not the directory — directory mount fails due to host dir permissions (`710`).

## File structure
- `Dockerfile` — image definition (node:20-bookworm base)
- `docker-compose.yml` — service config, volumes, bind mounts, port 9090
- `entrypoint.sh` — runtime setup (SSH, claude update, galaxy, MCP registration)
- `run.sh` — host-side launcher (writes .env, clones skills, opens editor, runs container)
- `.env` / `.env.example` — Galaxy credentials + GH_TOKEN (gitignored)

## Shell shortcuts (in ~/.bashrc)
- `cdl` — opens Sublime on current dir + launches container. No port mapping, can run multiple in parallel.
- `cdlg` — same but with `--service-ports` to expose port 9090 for Galaxy. Only one at a time (port conflict otherwise).

## Gotchas
- `docker-compose.yml` `env_file` must be `required: false` — `.env` may not exist if user runs `docker compose` directly without `run.sh`
- `cp -a` fails on ro bind mounts (tries to preserve ownership). Use plain `cp` for SSH keys.
- Host user must be in `docker` group. After `usermod -aG docker $USER`, need full logout/login. `newgrp docker` may ask for group password — use `exec newgrp docker` instead.
- After changing Dockerfile or entrypoint.sh, must `docker compose build` — entrypoint is COPYed into image.
- `docker compose run` does NOT map ports by default — must use `--service-ports` flag for Galaxy port 9090.
- gh config directory mount shows empty inside container. Mount individual files instead.
- **GPU**: nvidia-container-toolkit required on host. compose `deploy.resources.reservations` passes all GPUs. If no NVIDIA GPU, container still starts fine (deploy section is a soft reservation).
