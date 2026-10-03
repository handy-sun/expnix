#!/usr/bin/env bash
set -euo pipefail

npm i -g @anthropic-ai/claude-code@latest
npm i -g @openai/codex@latest
npm i -g --ignore-scripts @earendil-works/pi-coding-agent
npm i -g ccstatusline-zh

curl -fsSL https://omp.sh/install | sh

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain 1.94.0
