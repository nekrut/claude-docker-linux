# Claude Docker Linux

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in an isolated Docker container on Linux. Only `~/git` is visible to the container. Auth via bind-mounted `~/.claude` (OAuth from `claude login`, no API key needed).

Based on [nekrut/claude-code-docker](https://github.com/nekrut/claude-code-docker), adapted for Linux.

## Prerequisites

- Docker CE + docker-compose-plugin ([install guide](https://docs.docker.com/engine/install/ubuntu/))
- Your user in the `docker` group: `sudo usermod -aG docker $USER` (logout/login after)
- `claude login` completed on host (creates `~/.claude/.credentials.json`)
- GitHub CLI authenticated (`gh auth login`)

## Quick start

```bash
# Build
docker compose build

# Run interactive session (--service-ports to expose port 9090 for Galaxy)
docker compose run --rm --service-ports claude

# One-shot
docker compose run --rm --service-ports claude -p "explain this codebase"
```

### Shell shortcut

Add to `~/.bashrc`:

```bash
cdl() { subl --new-window "$(pwd)" & docker compose -f ~/git/claude-docker-linux/docker-compose.yml run --rm --service-ports claude "$@"; }
```

Then `source ~/.bashrc` and use from anywhere:

```bash
cd ~/git/myproject
cdl                          # opens Sublime on current dir + interactive Claude
cdl -p "explain this repo"   # one-shot
```

### With Galaxy (optional)

```bash
# Set Galaxy credentials
export GALAXY_URL=https://...
export GALAXY_API_KEY=sk-...

# Use run.sh (writes .env, clones galaxy-skills, opens Sublime, runs container)
./run.sh
```

## What's in the container

- **Base**: node:20-bookworm
- **Tools**: git, python3, gh, jq, curl, wget, sudo
- **Python**: uv, Miniconda3
- **AI**: claude-code (latest), galaxy-mcp (via uvx)

Claude runs with `--dangerously-skip-permissions` (suitable for isolated container use).

## Volumes

### Bind mounts (host filesystem)

| Host | Container | Mode |
|------|-----------|------|
| `~/git` | `/workspace` | rw |
| `~/.claude` | `/home/node/.claude` | rw |
| `~/.claude.json` | `/home/node/.claude.json` | rw |
| `~/.gitconfig` | `/home/node/.gitconfig` | ro |
| `~/.config/gh` | `/home/node/.config/gh` | ro |
| `~/.ssh` | `/home/node/.ssh` | ro |

### Named volumes (persist across container restarts)

| Volume | Path | Purpose |
|--------|------|---------|
| `pip-local` | `/home/node/.local` | pip user packages |
| `conda` | `/opt/conda` | conda environments |
| `uv-cache` | `/home/node/.cache/uv` | uv/uvx cache |

Packages installed via `pip install`, `conda install`, or `uv` persist across container restarts.

## Entrypoint

On each container start, `entrypoint.sh`:
1. Copies SSH keys to writable dir with correct permissions
2. Seeds conda volume from image (first run only)
3. Updates galaxy-mcp via uvx
4. Pulls latest galaxy-skills (if cloned)
5. Registers Galaxy MCP server (if not already configured)
6. Launches `claude --dangerously-skip-permissions`

## Galaxy integration

- **galaxy-mcp**: Pre-cached in image, updated on each container start, registered as MCP server
- **galaxy-skills**: Cloned to `~/.claude/skills/galaxy` on host, `git pull` on each start

## Multiple agents

Each `docker compose run --rm claude` starts a separate container. Run multiple in parallel from different terminals. All share the same `~/git` workspace — coordinate by having agents work on different repos or branches.
