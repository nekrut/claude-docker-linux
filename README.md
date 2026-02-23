# Claude Docker Linux

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in an isolated Docker container on Linux. Only `~/git` is visible to the container. Auth via bind-mounted `~/.claude` (OAuth from `claude login`, no API key needed).

Based on [nekrut/claude-code-docker](https://github.com/nekrut/claude-code-docker), adapted for Linux.

## Prerequisites

- Docker CE + docker-compose-plugin ([install guide](https://docs.docker.com/engine/install/ubuntu/))
- Your user in the `docker` group: `sudo usermod -aG docker $USER` (logout/login after)
- `claude login` completed on host (creates `~/.claude/.credentials.json`)
- GitHub personal access token with `repo` scope ([create here](https://github.com/settings/tokens))
- **GPU (optional)**: NVIDIA GPU + [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html):
  ```bash
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
  ```
  Verify with: `docker compose run --rm --entrypoint bash claude -c "nvidia-smi"`

## Setup

1. Clone and build:
```bash
git clone https://github.com/nekrut/claude-docker-linux.git ~/git/claude-docker-linux
cd ~/git/claude-docker-linux
cp .env.example .env
docker compose build
```

2. Add credentials to `.env`:
```
GALAXY_URL=https://...
GALAXY_API_KEY=sk-...
GH_TOKEN=ghp_...
```

3. Add shell shortcuts to `~/.bashrc`:
```bash
cdl() { subl --new-window "$(pwd)" & docker compose -f ~/git/claude-docker-linux/docker-compose.yml run --rm claude "$@"; }
cdlg() { subl --new-window "$(pwd)" & docker compose -f ~/git/claude-docker-linux/docker-compose.yml run --rm -p 9090:9090 claude "$@"; }
```

4. `source ~/.bashrc` (required after adding shortcuts, or open a new terminal)

## Usage

```bash
cd ~/git/myproject
cdl                          # opens Sublime + interactive Claude (can run multiple)
cdl -p "explain this repo"   # one-shot
cdlg                         # with Galaxy port 9090 mapped (only one at a time)
```

Or without the shortcut:
```bash
cd ~/git/claude-docker-linux
docker compose run --rm --service-ports claude
```

## What's in the container

- **Base**: node:20-bookworm
- **Tools**: git, python3, gh, jq, curl, wget, sudo
- **Python**: uv, Miniconda3
- **AI**: claude-code (latest, auto-updated on start), galaxy-mcp (via uvx)

Claude runs with `--dangerously-skip-permissions` (suitable for isolated container use).

## GitHub auth

The `gh` CLI inside the container uses `GH_TOKEN` from `.env`. Host-side keyring auth (default for `gh auth login`) is not accessible from the container — use a personal access token instead.

## Volumes

### Bind mounts (host filesystem)

| Host | Container | Mode |
|------|-----------|------|
| `~/git` | `/workspace` | rw |
| `~/.claude` | `/home/node/.claude` | rw |
| `~/.claude.json` | `/home/node/.claude.json` | rw |
| `~/.gitconfig` | `/home/node/.gitconfig` | ro |
| `~/.config/gh/hosts.yml` | `/home/node/.config/gh/hosts.yml` | ro |
| `~/.config/gh/config.yml` | `/home/node/.config/gh/config.yml` | ro |
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
3. Updates claude-code to latest version
4. Updates galaxy-mcp via uvx
5. Clones or pulls latest galaxy-skills
6. Registers Galaxy MCP server (if not already configured)
7. Launches `claude --dangerously-skip-permissions`

## Galaxy integration

- **galaxy-mcp**: Pre-cached in image, updated on each container start, registered as MCP server
- **galaxy-skills**: Cloned to `~/.claude/skills/galaxy` on host, `git pull` on each start
- **Port 9090**: Mapped to host for Galaxy web UI access

## Multiple agents

Each `docker compose run --rm claude` starts a separate container. Run multiple in parallel from different terminals. All share the same `~/git` workspace — coordinate by having agents work on different repos or branches.
